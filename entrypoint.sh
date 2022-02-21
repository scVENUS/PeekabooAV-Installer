#!/bin/sh -e

sed -e "s,{{ peekaboo_db_password }},${PEEKABOO_DB_PASSWORD:-secret},g" \
			-e "s,{{ mariadb_server }},${PEEKABOO_DB_SERVER:-mariadb},g" \
			-e "s,{{ peekaboo_listen_address }},${PEEKABOO_LISTEN_ADDRESS:-0.0.0.0},g" \
		/opt/peekaboo/etc/peekaboo.conf.template > /opt/peekaboo/etc/peekaboo.conf

sed -e "s,{{ cortex_url }},${PEEKABOO_CORTEX_URL:-http://cortex:9001},g" \
			-e "s,{{ cortex_api_token }},${PEEKABOO_CORTEX_API_TOKEN:-secret},g" \
		/opt/peekaboo/etc/analyzers.conf.template > /opt/peekaboo/etc/analyzers.conf

exec /opt/peekaboo/bin/peekaboo -c /opt/peekaboo/etc/peekaboo.conf -D -d
