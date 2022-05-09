FROM alpine:latest

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories  && \
    apk update && \
    apk add postfix \
            postfix-pcre \
            swaks \
            mailutils

RUN mkdir -p /etc/aliases && newaliases

EXPOSE 25

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD /entrypoint.sh
