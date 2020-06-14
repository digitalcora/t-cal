FROM crystallang/crystal:0.35.0-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
