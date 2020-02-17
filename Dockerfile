FROM crystallang/crystal:0.33.0-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
