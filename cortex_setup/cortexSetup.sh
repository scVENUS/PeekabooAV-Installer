#!/bin/sh

# tested with thehiveproject/cortex:3.1.4
# `auth.method.basic=true` is needed in the application.conf of Cortex

check_last_command () {
	if [ $? -eq 0 ]; then
		printf " \033[38;5;118mo\033[0m\n"
	else
		# switch cursor back on and reset colours before exiting
		printf "\033[?25h\033[0m\n"
		exit 1
	fi
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-cu|--cortex-url)
			shift
			if [ -z "$1" ] ; then
			       echo "Cortex URL argument missing"
			       exit 1
			fi
			CORTEX_URL="$1"
			;;
		-eu|--elasticsearch-url)
			shift
			if [ -z "$1" ] ; then
			       echo "Elastic URL argument missing"
			       exit 1
			fi
			ELASTIC_URL="$1"
			;;
		-k|--api-key)
			shift
			if [ -z "$1" ] ; then
			       echo "Cortex API key argument missing"
			       exit 1
			fi
			PEEKABOO_CORTEX_API_TOKEN="$1"
			;;
		-*|--*)
			echo "Unknown option $1"
			exit 1
			;;
		*)
			;;
	esac
	shift
done

if [ -z "$CORTEX_URL" ]; then
	echo "must specify a URL with -cu / --cortex-url (without path or trailing /, e.g. http://cortex:9001)"
	echo "Or set CORTEX_URL as an environment variable"
	exit 1
fi
if [ -z "$ELASTIC_URL" ]; then
	echo "must specify a URL with -eu / --elasticsearch-url (without path or trailing /, e.g. http://elasticsearch:9200)"
	echo "Or set ELASTIC_URL as an environment variable"
	exit 1
fi
if [ -z "$PEEKABOO_CORTEX_API_TOKEN" ] ; then \
	echo "Specify an arbitrary, but secure;), API key with -k / --api-key"
	echo "or set PEEKABOO_CORTEX_API_TOKEN as an environment variable"
	exit 1
fi
if [ -n "$(echo "$PEEKABOO_CORTEX_API_TOKEN" | tr -d "[a-zA-Z0-9+/]")" ]; then
	echo "The Cortex API key must only use alphanumeric characters."
	exit 1
fi

# switch off cursor
printf "\033[?25l"

CODE=$(curl -s -o /dev/null -w "%{http_code}" "$CORTEX_URL/api/job")
printf "\033[38;5;242m$CODE\033[0m\n"

if [ $CODE -eq "520" ]; then
	echo
	echo "Cortex needs to be set-up"

	if [ -z $CORTEX_ADMIN_PASSWORD ]; then
		CORTEX_ADMIN_PASSWORD=$(pwgen -s1 16)
		echo "auto-generated cortex admin password: $CORTEX_ADMIN_PASSWORD"
	fi

	printf "\t\033[38;5;226mMigrate Database... \033[0m"
	curl -f -s -o /dev/null -XPOST -H 'Content-Type: application/json' \
		"$CORTEX_URL/api/maintenance/migrate" -d '{}'
	sleep 3
	check_last_command

	printf "\t\033[38;5;226mMake admin user... \033[38;5;242m"
	curl -f -s -o /dev/null -XPOST -H 'Content-Type: application/json' \
		"$CORTEX_URL/api/user" \
		-d '{"login":"admin","name":"admin","password":"'"$CORTEX_ADMIN_PASSWORD"'","roles":["superadmin"],"organization":"cortex"}'
	check_last_command

	printf "\t\033[38;5;226mCreate organization 'PeekabooAV'... \033[38;5;242m"
	curl -f -s -o /dev/null -XPOST -u "admin:$CORTEX_ADMIN_PASSWORD" \
		-H 'Content-Type: application/json' "$CORTEX_URL/api/organization" \
		-d '{ "name": "PeekabooAV", "description": "PeekabooAV organization", "status": "Active"}' 
	check_last_command

	printf "\t\033[38;5;226mCreate orgAdmin user... \033[38;5;242m"
	curl -f -s -o /dev/null -XPOST -u "admin:$CORTEX_ADMIN_PASSWORD" \
		-H 'Content-Type: application/json' "$CORTEX_URL/api/user" \
		-d '{ "name": "Peekaboo org Admin","password":"'"$CORTEX_ADMIN_PASSWORD"'","roles": ["read","analyze","orgadmin"], "organization": "PeekabooAV", "login": "peekaboo-admin" }'
	check_last_command
	ORG_ADMIN_KEY=$(curl -s -XPOST -u "admin:$CORTEX_ADMIN_PASSWORD" -H 'Content-Type: application/json' "$CORTEX_URL/api/user/peekaboo-admin/key/renew")

	printf "\t\033[38;5;226mCreate normal user... \033[38;5;242m"
	curl -f -s -o /dev/null -XPOST \
		-H "Authorization: Bearer $ORG_ADMIN_KEY" \
		-H 'Content-Type: application/json' "$CORTEX_URL/api/user" \
		-d '{ "name": "Peekaboo", "roles": ["read","analyze"], "organization": "PeekabooAV", "login": "peekaboo-analyze" }'
	check_last_command

	printf "\t\033[38;5;226mGet cortex elasticsearch index... \033[38;5;242m"
	ELASTIC_INDEX=$(curl -s "$ELASTIC_URL/_search?q=_id:peekaboo-analyze" | \
		jq -r ".hits.hits[]._index // empty")
	if [ -z "$ELASTIC_INDEX" ] ;then
		printf "\033[38;5;197mThere was no _index found in Elastiscsearch response\033[0m\033[?25h\n"
		exit 1
	fi
	check_last_command
	printf "\t\t\033[38;5;242m"
	echo "Index: $ELASTIC_INDEX"

	printf "\t\033[38;5;226mPlace own API key in the database... \033[38;5;242m"
	curl -f -s -o /dev/null -XPOST -H 'Content-Type: application/json' \
		-d '{"doc": {"key": "'"$PEEKABOO_CORTEX_API_TOKEN"'"}}' "$ELASTIC_URL/$ELASTIC_INDEX/_update/peekaboo-analyze"
	check_last_command

	printf "\t\033[38;5;226mEnable FileInfo 8.0 Analyzer... \033[38;5;242m"
	curl -f -s -o /dev/null -XPOST \
		-H "Authorization: Bearer $ORG_ADMIN_KEY" \
		-H 'Content-Type: application/json' "$CORTEX_URL/api/organization/analyzer/FileInfo_8_0" \
		-d '{"name": "FileInfo_8_0", "configuration": {}}'
	check_last_command

elif [ $CODE -eq "401" ]; then
	echo "Cortex does not need to be set-up"
fi

printf "\033[32mAll good!\033[0m\033[?25h\n"

exit 0
