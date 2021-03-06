# TCal

<p class="subtitle">
  An iCal feed of planned service disruptions on MBTA rapid transit.
</p>

<p class="screenshot">
  <img alt="Screenshot of TCal events on Google Calendar" src="/screenshot.png">
</p>

<p class="repo-link">
  See also the open-source code
  <a href="https://github.com/digitalcora/t-cal">on GitHub</a>.
</p>

## ℹ How to use

### `https://t-cal.herokuapp.com/alerts.ics`

↑ Copy this iCal URL and add it to your calendar app.

The process for doing this varies wildly, but in the end you're looking for a
box you can paste a URL into (_not_ something that asks you to upload a file).
Look for words like "feed", "sync", or "subscribe". If you're stuck, try a web
search for _"add ical feed to `<calendar app name>`"_.


## ⚠ Limitations

* The calendar only shows disruptions on rapid transit lines (Blue, Green,
  Orange, Red). If you need to know about Commuter Rail or bus disruptions, try
  [**T-Alerts**](https://alerts.mbta.com/).

* The calendar only shows disruptions whose "severity" is 5 or greater (on a
  scale of 0 to 10). This is a balance between over-cluttering the calendar and
  surfacing useful information, and I'm open to tweaking it.

* To create a clean calendar view, TCal rounds time values that are close to a
  day boundary. This means that e.g. a disruption lasting until "end of service"
  at 2:30am will appear to end at midnight. Most alerts include an mbta.com URL
  you can check for the official timing.


## 💬 Report an issue

1. Check whether your issue also appears in the [alerts on mbta.com]. If so,
   please [**report it to the MBTA**][report]. The calendar is auto-generated
   from alerts data, and I can't fix issues that originate there.

2. Check TCal's **[open issues]** on GitHub to see if your issue has already
   been reported. If it's there, I know about it and will respond when I can.

3. Otherwise, feel free to [**submit a new issue**][new-issue]! _(requires a
   GitHub account)_

[alerts on mbta.com]: https://mbta.com/alerts/subway
[report]: https://www.mbta.com/customer-support
[open issues]: https://github.com/digitalcora/t-cal/issues
[new-issue]: https://github.com/digitalcora/t-cal/issues/new


## ⚙ Advanced usage

### Text format

To easily inspect the iCal output in a browser, replace `.ics` with `.txt` in
the URL and the calendar will be served as text.

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

#### Known to support `VALUE=PERIOD`:

* Google Calendar

#### Known to require compat mode:

* Apple Calendar
* Fastmail
* Outlook Web App


## 💻 About the author

I'm Cora, a software engineer on the MBTA's [Customer Technology][ctd] team. I
created this project in my spare time using our [public data and APIs][devs],
partly as an exercise in learning [Crystal] and partly to bring more clarity to
the MBTA's numerous shuttle diversions.

[ctd]: https://ctd.mbta.com/
[devs]: https://www.mbta.com/developers
[Crystal]: https://crystal-lang.org/
