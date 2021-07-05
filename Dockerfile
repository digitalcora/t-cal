FROM crystallang/crystal:1.0.0-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
