#!/bin/sh

set -e

# Notifies Rollbar of a Heroku deploy. Requires the `runtime-dyno-metadata` lab.

if [ -n "$HEROKU_RELEASE_VERSION" ] && [ -n "$ROLLBAR_ACCESS_TOKEN" ]; then
  curl --silent --request POST \
    --url https://api.rollbar.com/api/1/deploy/ \
    --header 'content-type: application/json' \
    --data "{
      \"access_token\": \"$ROLLBAR_ACCESS_TOKEN\",
      \"environment\": \"production\",
      \"revision\": \"$HEROKU_RELEASE_VERSION\",
      \"local_username\": \"heroku\"
    }"
else
  echo "Skipping deploy notification: required env vars missing"
fi
