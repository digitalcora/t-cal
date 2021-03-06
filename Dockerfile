FROM crystallang/crystal:0.36.1-alpine
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
