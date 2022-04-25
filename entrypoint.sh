#!/bin/sh -e

cat <<EOF >/opt/peekaboo/etc/peekaboo.conf.d/05-entrypoint.conf
[global]
host: ${PEEKABOO_LISTEN_ADDRESS:-0.0.0.0}

[logging]
log_level: ${PEEKABOO_LOG_LEVEL:-DEBUG}

[db]
url: mysql+mysqldb://peekaboo:${PEEKABOO_DB_PASSWORD:-secret}@${PEEKABOO_DB_SERVER:-mariadb}/peekaboo
EOF

cat <<EOF >/opt/peekaboo/etc/analyzers.conf.d/05-entrypoint.conf
# entrypoint only supports cortex as of now
[cortex]
url: ${PEEKABOO_CORTEX_URL:-http://cortex:9001}
api_token: ${PEEKABOO_CORTEX_API_TOKEN:-secret}
EOF

# entrypoint can not configure ruleset as of now

exec /opt/peekaboo/bin/peekaboo -c /opt/peekaboo/etc/peekaboo.conf -D -d
