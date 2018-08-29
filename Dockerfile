FROM alpine
WORKDIR /app
ADD README.md README.md
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*
ADD run.sh run.sh
ENTRYPOINT ["/app/run.sh"]
