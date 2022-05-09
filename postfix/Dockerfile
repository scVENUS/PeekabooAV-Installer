FROM alpine:latest

RUN apk add --no-cache postfix postfix-pcre && \
	apk --no-cache --repository='https://dl-cdn.alpinelinux.org/alpine/edge/testing' \
		add swaks

RUN mkdir -p /etc/aliases && newaliases

EXPOSE 25

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD /entrypoint.sh
