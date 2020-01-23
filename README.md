# TCal

Generates an iCal feed of planned service disruptions on MBTA rapid transit.

* **Included:** Blue, Green, Orange, Red
* **Not included:** Buses, Commuter Rail, Ferries


## How to use

**`https://t-cal.herokuapp.com/alerts.ics`**

⬆ Copy this iCal URL and add it to your calendar app.

The process for doing this varies wildly, but in the end you're looking for a
box you can paste a URL into (_not_ something that asks you to upload a file).
Look for words like "feed", "sync", or "subscribe". If you're stuck, try a web
search for _"add ical feed to `<calendar app name>`"_.


## Limitations

* The calendar only shows disruptions on rapid transit lines (Blue, Green,
  Orange, Red). If you need to know about Commuter Rail or bus disruptions, try
  [**T-Alerts**](https://alerts.mbta.com/).

* The calendar only shows disruptions whose "severity" is 5 or greater (on a
  scale of 0 to 10). This is a balance between over-cluttering the calendar and
  surfacing useful information, and I'm open to tweaking it.

* To create a clean calendar view, TCal "snaps" time values that are close to
  the start/end of the day to exactly the start/end of the day. This means that,
  for example, a shuttle bus diversion that runs until "end of service" at
  2:30am will appear to end at midnight. Check the "more info" link included in
  most alerts for the official timing.


## Report an issue

The calendar is generated automatically from MBTA alerts data. If you notice a
mistake or inconsistency, first check whether it also appears in the [alerts on
mbta.com]. If it does, please [**report it directly to the MBTA**][report].

[alerts on mbta.com]: https://mbta.com/alerts/subway
[report]: https://www.mbta.com/customer-support

Otherwise, [check the open issues][issues] to see if your issue has already been
reported. If not, feel free to [submit a new one][new-issue]!

[issues]: https://github.com/digitalcora/t-cal/issues
[new-issue]: https://github.com/digitalcora/t-cal/issues/new


## Advanced usage

### Text format

To easily inspect the iCal output in a web browser, replace `.ics` with `.txt`
in the URL and the calendar will be served as plain text.

### Compat mode

The ideal version of the calendar uses [`RDATE;VALUE=PERIOD`][rdate] to express
each disruption as a single recurring event. Unfortunately many calendar apps
don't support this part of the iCal standard, so unless TCal knows that yours
does, it defaults to "compat mode", where each time-block of a disruption is a
separate event.

[rdate]: https://tools.ietf.org/html/rfc5545#section-3.8.5.2

You can override the auto-detection by adding `?compat=true` or `?compat=false`
to the end of the URL, which will force compat mode on or off respectively. If
you find your calendar app works fine without compat mode and it's not already
on the Nice List below, please do [file an issue] to have it added!

[file an issue]: https://github.com/digitalcora/t-cal/issues/new

#### Known to support `VALUE=PERIOD`

* Google Calendar

#### Known to require compat mode

* Apple Calendar
* Outlook Web App


## About the author

I'm Cora, a software engineer on the MBTA's [Customer Technology][ctd] team. I
created this project in my spare time using our [public data and APIs][devs].

[ctd]: https://medium.com/mbta-tech
[devs]: https://www.mbta.com/developers
