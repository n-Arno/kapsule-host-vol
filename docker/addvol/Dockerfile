FROM alpine:latest

RUN apk add --no-cache curl && \
    curl -sSL https://raw.githubusercontent.com/scaleway/scaleway-cli/master/scripts/get.sh | sh

COPY run.sh /run.sh

ENTRYPOINT "/run.sh"
