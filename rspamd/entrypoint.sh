#!/bin/sh -e

locald=/etc/rspamd/local.d

# trie has no enabled parameter we cannot explicitly enable or disable it.
NON_ENABLEABLE_MODULES="trie"

# leave default config alone if not set
if [ -n "$RSPAMD_ENABLED_MODULES" ] ; then
	for plugindirlua in /usr/share/rspamd/plugins/*.lua ; do
		pluginlua=${plugindirlua##*/}
		module=${pluginlua%.lua}

		enabled=false
		doing=Dis
		echo " ${RSPAMD_ENABLED_MODULES} "  | \
			grep " ${module} " > /dev/null 2>&1 && \
			enabled=true && doing=En

		if echo " $module " | grep " ${NON_ENABLEABLE_MODULES} " \
				> /dev/null 2>&1 ; then
			echo "entrypoint: Leaving alone module ${module}"
		else
			echo "entrypoint: ${doing}abling module ${module}"
			echo "enabled = ${enabled};" \
				>> "$locald"/"$module".conf
		fi
	done
fi

# here it gets somewhat fancy: below code allows to set arbitrary config
# options from environment variables by scanning and interpreting them
# according to the following rules:
#
# - variable name needs to start with RSPAMD_CONFIG_
# - the last component is the name of the setting to place into the config
# - the variable value is the setting value
#     RSPAMD_CONFIG_setting="value" -> setting = value;
#   (note the missing quotes)
#
# - string values that are to end up quoted in the config file need are denoted
#   by ending the variable name in a single underscore:
#     RSPAMD_CONFIG_setting_="value" -> setting = "value";
#   (note the quotes present)
#
# - section names are separated from values using double underscores:
#     RSPAMD_CONFIG_section__setting="value"
#     RSPAMD_CONFIG_section__section2__setting2_="value2"
#     ->
#     section {
#       setting = value;
#       section2 {
#         setting2 = "value";
#       }
#     }
#
# - arrays can be given in short notation as values:
#     RSPAMD_CONFIG_array="['value1', 'value2']"
#     -> array = ['value1', 'value2'];
#
# - arrays can also be given in multiple variables distinguished and ordered by
#   at least double digits in front of the option name:
#     RSPAMD_CONFIG_01_array="value1"
#     RSPAMD_CONFIG_02_array="value2"
#     ->
#     array = [
#       value1,
#       value2
#     ];
#   (note the missing quotes around the values - go underscore for strings)
#
# To put all this to use one has to know the layout of the rspamd configuration
# object tree. Unfortunately it's somewhat obscured by the way its buildup is
# (somewhat inconsistently) delegated to various include files. That's also why
# we don't even try to use these individual config files as targets for our
# output here. This is an excerpt of what we've been interested in so far:
#
# options {
#   filters = "";
# }
#
# group {
#   antivirus {
#     symbols {
#       IDENTIFIER {
#         weight: 4.0 ...
#
# -> group settings are inconsistent in the stock config in that they delegate
# to a groups.conf but still configure individual group objects starting at the
# top level of the tree.
#
# force_actions {
#   rules {
#     IDENTIFIER {
#       action: "reject" ...
#
# troubleshooting tip: cfg; rspamd_config_read: failed to load config: ucl
# parser error: error while parsing /etc/rspamd/local.d/entrypoint.conf: line:
# 2, column: 12 - 'string value must not be empty', character: ';'
#
# make sure your empty string value is marked as a string using trailing
# underscore:
#   RSPAMD_CONFIG_options__filters="" -> options { filters = ; } <- bad
#   RSPAMD_CONFIG_options__filters_="" -> options { filters = "";} <- good[tm]

# this is a function so that when called from a pipe (which is an implicit
# subshell) we can have multiple sucessive steps such as loops seeing the same
# "local" variables
process() {
	opensections=""
	while IFS== read var value ; do
		# track changes in sections based on variable names
		stillopensections=""
		while [ -n "$opensections" ] ; do
			section="${opensections%%__*}"
			restsections="${opensections#*__}"

			restvar="$(echo "$var" | sed "s,^${section}__,,")"
			[ "$restvar" != "$var" ] || break
			var="$restvar"

			opensections="${restsections}"
			stillopensections="${stillopensections}${section}__"
		done

		# opensections contains the open sections from the last
		# iteration we didn't find in the new variable name which
		# potentially need closing

		# var contains the trailing part of the new variable name which
		# we couldn't match up with the open sections from the last
		# iteration. So this possibly needs opening some new sections
		# before we can put down the actual setting and value.

		# if we changed sections, close the ones we left
		while [ -n "$opensections" ] ; do
			opensections="${opensections#*__}"
			indent="${indent%  }"
			echo "$indent}"
		done
		opensections="$stillopensections"

		# loop over the remaining variable name parts and open sections
		# and put down the value as required
		while [ -n "$var" ] ; do
			section="${var%%__*}"
			rest="${var#*__}"

			if [ "$section" = "$var" ] ; then
				# see if this is marked as a string that needs
				# quoting
				str=${var%_}
				[ "$str" = "$var" ] || value="\"$value\""

				# see if this is marked as an array
				arr=${str#[0-9][0-9]*_}

				# potentially close an array we were adding
				# values to in the last iteration
				if [ -n "$openarray" -a "$arr" != "$openarray" ] ; then
					indent="${indent%  }"
					printf "\n$indent];\n"
					openarray=""
				fi

				# potentially open the new array
				if [ -z "$openarray" -a "$arr" != "$str" ] ; then
					printf "$indent$arr = ["
					indent="$indent  "
					openarray="$arr"
					arrsep=""
				fi

				# put down the value, distinguishing between a
				# plain option and an array
				if [ -n "$openarray" ] ; then
					printf "$arrsep\n$indent$value"
					arrsep=","
				else
					echo "$indent$str = $value;"
				fi

				rest=""
			else
				# open a new section if necessary and record it
				# in opensections
				echo "$indent$section {"
				indent="$indent  "
				opensections="${opensections}${section}__"
			fi

			var="$rest"
		done
	done

	# close still open sections at the end
	while [ -n "$opensections" ] ; do
		opensections="${opensections#*__}"
		indent="${indent%  }"
		echo "$indent}"
	done
}

# generate our config overrides over the distributed configuration. We put it
# very last in rspamd.conf which allows us to override all other options. Users
# can still override our settings using rspamd's override mechanism. Although,
# they shouldn't need to because our mechanics should allow to configure every
# single setting using an environment variable.

# LC_ALL=C makes sure variable names are grouped at the two-dash delimiters
# instead of treating them identical to a single dash and mixing up sections
#
# example:
# $ printf "a__a\na_a\na__b\na_b\n" | sort | tr '\n' ' '
# a__a a_a a__b a_b
# $ printf "a__a\na_a\na__b\na_b\n" | LC_ALL=C sort | tr '\n' ' '
# a__a a__b a_a a_b
env | grep ^RSPAMD_CONFIG_ | sed "s,^RSPAMD_CONFIG_,," | LC_ALL=C sort | \
	process > "$locald"/entrypoint.conf

echo '.include(try=true; priority=1,duplicate=merge) ' \
	'"$LOCAL_CONFDIR/local.d/entrypoint.conf"' >> /etc/rspamd/rspamd.conf

[ -z "$RSPAMD_DEBUG_CONFIG" ] || \
	grep .* "$locald"/*.conf "$locald"/*.inc

exec /usr/sbin/rspamd -i -f
