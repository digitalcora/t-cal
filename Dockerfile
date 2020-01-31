FROM crystallang/crystal:0.32.1
RUN apt-get update
RUN apt-get install -y curl
WORKDIR /app
COPY . .
RUN shards build --production --release
CMD ["bin/server"]
