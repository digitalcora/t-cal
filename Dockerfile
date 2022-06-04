FROM crystallang/crystal:1.4.1-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
