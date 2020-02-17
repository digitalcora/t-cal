# TCal

An iCal feed of planned service disruptions on MBTA rapid transit.

ℹ **See the [TCal web site](https://t-cal.herokuapp.com) for usage!**


### Setup

1.  [`asdf install`](https://github.com/asdf-vm/asdf)
2. `shards install`

If `asdf` doesn't work, check the
[Crystal install steps](https://crystal-lang.org/install/)
for your platform.


### Development

* Run the server: `crystal src/main.cr`
* Generate docs: `crystal docs` _(then open `docs/index.html`)_
* Lint the code: `bin/ameba`


### Production

To build a standalone binary `bin/server`:

* `shards build --production --release`

The current production instance runs on Heroku. Setup steps:

1. [`heroku create`](https://devcenter.heroku.com/articles/heroku-cli)
2. `heroku stack:set container`
3. `heroku config:set HOST=0.0.0.0`
4. `git push heroku master`


### Configuration

The server supports these environment variables:

* `HOST` — The network address to listen on. Default value is `127.0.0.1`,
  meaning the server will only be accessible from localhost. Use `0.0.0.0` to
  listen on all addresses.

* `PORT` — The TCP port to listen on. Default value is `8080`.
