# TCal

A calendar of planned service disruptions on MBTA rapid transit, provided as a
web page and an iCal feed. See the live site at: https://tcal.digitalcora.net


### Setup

1. [Install Crystal](https://crystal-lang.org/install/)
2. `shards install`

[`asdf install`](https://github.com/asdf-vm/asdf) may also be used, but is not
recommended, since this doesn't install any of the system-level packages Crystal
depends on.


### Development

* Run the server: `crystal src/main.cr`
* Generate docs: `crystal docs` _(then open `docs/index.html`)_
* Lint the code: `bin/ameba`


### Production

To build a standalone binary `bin/server`:

* `shards build --production --release --static`

The current production instance runs on [Fly](https://fly.io/), using the
`fly.toml` included in the repo.


### Configuration

The server supports these environment variables:

* `HOST` — The network address to listen on. Default value is `127.0.0.1`,
  meaning the server will only be accessible from localhost. Use `0.0.0.0` to
  listen on all addresses.

* `PORT` — The TCP port to listen on. Default value is `8080`.

* `ORIGIN` — The canonical origin (scheme + host + optional port) of the site.
  When a request includes a `Host` and it is not the canonical origin's host,
  it will be redirected to the same path at the canonical origin. Default value
  is `http://localhost` plus the configured `PORT`.

* `LOG_LEVEL` — The log level. Default value is `info`. See the
  [`Log`](https://crystal-lang.org/api/Log.html) documentation for valid log
  levels.

* `SENTRY_DSN` — If set, unhandled exceptions will be reported to
  [Sentry](https://sentry.io/).

* `SENTRY_ENVIRONMENT` — The environment string used for Sentry reports, if
  enabled. Default value is `default`.
