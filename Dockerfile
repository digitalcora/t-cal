# == Build stage

FROM crystallang/crystal:1.6.2-alpine AS build

# Needed to auto-populate the Sentry release tag from the current commit SHA:
# https://github.com/Sija/raven.cr/blob/d53319d/src/raven/configuration.cr#L333
RUN apk add git
RUN git config --global --add safe.directory /app

WORKDIR /app
COPY . .
RUN shards build --production --release --static


# == Runtime stage

# Use the same base image as the build stage:
# https://github.com/crystal-lang/distribution-scripts/blob/e9cafa1/docker/alpine.Dockerfile#L1
FROM alpine:3.16

RUN apk add --update tzdata

WORKDIR /app
COPY --from=build /app/bin/ bin/
COPY --from=build /app/src/t_cal/assets/ src/t_cal/assets/

CMD ["bin/raven.crash_handler", "bin/server"]
