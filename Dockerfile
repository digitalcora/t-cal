FROM crystallang/crystal:0.32.1
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
