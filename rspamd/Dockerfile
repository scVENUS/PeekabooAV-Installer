FROM alpine:3.15

RUN apk add rspamd \
	rspamd-proxy \
	patch

COPY peekaboo.lua /usr/share/rspamd/lualib/lua_scanners/
COPY peekaboo.patch /root/

RUN patch -t -p1 < /root/peekaboo.patch && \
	echo 'bind_socket = "0.0.0.0:11332";' >> /etc/rspamd/local.d/worker-proxy.inc && \
	echo 'type = "console";' >> /etc/rspamd/local.d/logging.inc && \
	mkdir -p /run/rspamd

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
