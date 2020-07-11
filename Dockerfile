FROM crystallang/crystal:0.35.1-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
