# TCal

An iCal feed of planned service disruptions on MBTA rapid transit.

ℹ **See the [TCal web site](https://t-cal.herokuapp.com) for usage!**


### Setup

1.  [`asdf install`](https://github.com/asdf-vm/asdf)
2. `shards install`

If `asdf` doesn't work, check the [Crystal install steps][crystal-install] for
your platform.

[crystal-install]: https://crystal-lang.org/install/


### Development

* Run the server: `crystal src/t_cal.cr`
* Generate docs: `crystal docs` _(then open `docs/index.html`)_


### Production

To build a standalone production binary `bin/t_cal`:

* `shards build --production --release --no-debug`

The current production instance runs on Heroku. Setup steps:

1. [`heroku create`](https://devcenter.heroku.com/articles/heroku-cli)
2. `heroku buildpacks:set https://github.com/crystal-lang/heroku-buildpack-crystal.git`
3. `heroku config:set HOST=0.0.0.0`
4. `git push heroku master`
