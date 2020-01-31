#!/bin/sh

set -e

# Notifies Rollbar of a Heroku deploy. Requires the `runtime-dyno-metadata` lab.
# HEROKU_SLUG_COMMIT doesn't appear to actually update for apps on the container
# stack, so parsing the short hash out of HEROKU_SLUG_DESCRIPTION instead.

if [ -n "$HEROKU_SLUG_DESCRIPTION" ] && [ -n "$ROLLBAR_ACCESS_TOKEN" ]; then
  revision=$(echo "$HEROKU_SLUG_DESCRIPTION" | sed -e 's/Deploy //')
  curl --silent --request POST \
    --url https://api.rollbar.com/api/1/deploy/ \
    --header 'content-type: application/json' \
    --data "{
      \"access_token\": \"$ROLLBAR_ACCESS_TOKEN\",
      \"environment\": \"production\",
      \"revision\": \"$revision\",
      \"local_username\": \"heroku\"
    }"
else
  echo "Skipping deploy notification: required env vars missing"
fi
