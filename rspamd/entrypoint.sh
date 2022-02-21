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

# TODO: Make subsections and arrays work somehow
varprefix=RSPAMD_OPTIONS_
env | grep "^$varprefix" | sed "s,^$varprefix,," |
	while IFS== read parameter value ; do
		parameter=$(echo "$parameter" | tr 'A-Z' 'a-z')
		echo "entrypoint: Setting option $parameter to '$value'"
		echo "$parameter = \"$value\";" >> "$locald"/options.inc
	done

exec rspamd -i -f
