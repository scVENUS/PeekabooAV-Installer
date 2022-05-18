FROM alpine:latest
RUN apk add --no-cache curl pwgen jq

COPY cortexSetup.sh /
RUN chmod 755 /cortexSetup.sh

ENTRYPOINT ["/cortexSetup.sh"]
