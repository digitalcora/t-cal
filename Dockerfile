FROM crystallang/crystal:1.2.2-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
