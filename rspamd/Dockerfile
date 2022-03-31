FROM alpine:3.15

RUN apk add rspamd \
	rspamd-proxy \
	patch

COPY peekaboo-integration/* /etc/rspamd/local.d/

RUN patch -t -p1 < /etc/rspamd/local.d/integration.patch && \
	sed -i 's/bind_socket = "localhost:11332";/bind_socket = "0.0.0.0:11332";/' /etc/rspamd/worker-proxy.conf && \
	mkdir -p /run/rspamd

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
