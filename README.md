# TCal

A calendar of planned service disruptions on MBTA rapid transit, provided as a
web page and an iCal feed. See the live site at: https://tcal.digitalcora.net


### Setup

[Install Crystal](https://crystal-lang.org/install/) using a supported method
for your operating system.

The currently-used version is declared in `.tool-versions`, but using e.g.
[`asdf`](https://github.com/asdf-vm/asdf) to install it is not recommended,
since it may not install the system-level packages Crystal depends on.


### Development

* Run the server: `shards run server`
* Generate docs: `crystal docs` _(then open `docs/index.html`)_
* Lint the code: `shards run ameba`


### Production

To build a standalone binary `bin/server`:

* `shards build server --production --release --static`

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

* `LOG_TIME` — If set to `true`, logs are prefixed with timestamps. Default
  value is `true`.

* `SENTRY_DSN` — If set, unhandled exceptions will be reported to
  [Sentry](https://sentry.io/).

* `SENTRY_ENVIRONMENT` — The environment string used for Sentry reports, if
  enabled. Default value is `default`.
