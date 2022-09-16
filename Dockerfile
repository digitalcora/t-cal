FROM crystallang/crystal:1.5.1-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/raven.crash_handler", "bin/server"]
