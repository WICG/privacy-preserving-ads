# Attribution Reporting
## Overview
Attribution reporting is a strategy that allows marketers and sales teams to track the impact of their marketing efforts on specific goals, such as purchases or sales.  Traditionally, ad conversion measurement relied on third-party cookies, which could be used to track users across sites and raised privacy concerns. To facilitate these measurements without tracking, a new reporting API is required.  Microsoft Edge is supporting a limited version of reporting, with reports being sent per-event. Future work includes replacing these event-level reports with aggregation reporting.

# Attribution Sources
There are two types of attribution sources - navigation and event sources.  An attribution source is eligible for reporting if any page on any of the associated destination sites (advertiser sites) triggers attribution for the associated reporting origin.

## Navigation Sources (Click)
Navigation sources are activated when a navigation occurs within the [transient user activation](https://html.spec.whatwg.org/multipage/interaction.html#transient-activation) time frame.  There are two ways to register navigation sources.
1.  When the user clicks on an anchor element with an “attributionsrc” attribute:

   ```
   <a href="https://advertiser.example/landing" attributionsrc="https://adtech.example/attribution_source?id=123"> Click Here </a>
   ```
2. Within the window.open call, with “attributionsrc” included in the specs:
```
// Encoding the attributionsrc URL ensures that special characters will be properly parsed.
const encoded = encodeURIComponent('https://adtech.example/attribution_source?id=123');
window.open(
  "https://advertiser.example/landing",
  "_blank",
  'attributionsrc=${encoded}');
```
## Event Sources (View)
Event sources do not require any user interaction to activate.  There are two ways to register event sources.
1.  Via \<img> or \<script> elements that have an “attributionsrc” attribute:
```
<img src="https://advertiser.example/pixel" attributionsrc="https://adtech.example/attribution_source?id=123">
<script src="https://advertiser.example/register-view" attributionsrc="https://adtech.example/attribution_source?id=123">
```
2. By using existing JavaScript request APIs by setting the appropriate option:
```
const attributionReporting = {
  eventSourceEligible: true,
  triggerEligible: false,
};
// Keepalive can be used to ensure the request outlives the page.
window.fetch("https://adtech.example/attribution_source?id=123", { keepalive: true, attributionReporting });
```
## Request and Response Headers:
When the user interacts with an attribution source, it sends an Attribution-Reporting-Eligible header on a request to the server measuring the interactions (typically the advertiser's server), which indicates that the response is eligible to register a source.
```
Attribution-Reporting-Eligible: navigation-source
```
When the server receives a request that includes an Attribution-Reporting-Eligible header, it can include an Attribution-Reporting-Register-Source header along with the response to complete source registration. Its value is a JSON string that provides the information the browser should store about the attribution source that was interacted with. The information included in this header also determines which types of report the browser will generate.
```
res.set(
  "Attribution-Reporting-Register-Source",
  JSON.stringify({
    source_event_id: <event ID here>
    destination: "https://advertiser.example",
    trigger_data: [0,1,2,3,4],
    trigger_data_matching: "exact",
    expiry: <expiry time in seconds for source>
    priority: <a higher priority number prioritises a source>
  }),
);
```
See [Attribution-Reporting-Register-Source](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Attribution-Reporting-Register-Source) for a detailed description of all the fields available in this header.

# Attribution Triggers
Once attribution sources have been registered, attribution triggers must be registered.  An attribution source is eligible for reporting if any page on any of the destination sites triggers attribution for the associated reporting origin.

There are two types of attribution triggers – HTML based and Javascript based.
## HTML Based Triggers
HTML-based attribution triggers can be used for detecting conversions on a page when an \<img> or \<script> element loads.  You can register an attribution trigger by adding the attributionsrc attribute to the appropriate element. The registration request is sent to the URL inside the attributionsrc value. If you leave the attributionsrc  value blank, the registration request will be sent to the server the requested resource is hosted on.
```
<img src="https://advertiser.example/conversionpixel" attributionsrc="https://adtech.example/attribution_trigger?purchase=456">
```
## Javascript Based Triggers
JavaScript-based attribution triggers will trigger the browser to attempt a match with a stored source based on a custom interaction.  There are two ways to register a JS based trigger:

A  fetch() request containing the attributionReporting  option:
```
const attributionReporting = {
  eventSourceEligible: false,
  triggerEligible: true,
};

function triggerMatching() {
  fetch("https://shop.example/endpoint", {
    keepalive: true,
    attributionReporting,
  });
}

// Associate the trigger with an element.
elem.addEventListener("click", triggerMatching);
```
An XMLHttpRequest with setAttributionReporting() invoked on the request object:
```
const attributionReporting = {
  eventSourceEligible: false,
  triggerEligible: true,
};

function triggerMatching() {
  const req = newXMLHttpRequest();
  req.open("GET", https://shop.example/endpoint");

  if (typeof req.setAttributionReporting === "function") {
    req.setAttributionReporting(attributionReporting);
    req.send();
  } else {
    throw new Error("Attribution reporting not available");
    // Add additional recovery code here as needed.
  }
}

// Associate the trigger with an element.
elem.addEventListener("click", triggerMatching);
```
## Request and Response Headers:
All of the trigger types send an Attribution-Reporting-Eligible header on a request, which indicates that the response is eligible to register a trigger.
```
Attribution-Reporting-Eligible: trigger
```
When the server receives a request that includes an Attribution-Reporting-Eligible header, it can include an [Attribution-Reporting-Register-Trigger](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Attribution-Reporting-Register-Trigger) along with the response. Its value is a JSON string containing data that can be included in generated reports, such as the ID of the trigger, priority, deduplication, and other values.
```
res.set(
  "Attribution-Reporting-Register-Trigger",
  JSON.stringify({
    "event_trigger_data": [
      {
        "trigger_data": <trigger value>,
        "priority": <a higher priority number prioritises a source>
        "deduplication_key": <a key for preventing attributions from being duplicated>
      }
    ],
  });
);

```
When the user interacts with the attribution trigger, the browser attempts to match the trigger against any attribution source entries stored in the browser's private local cache. There are several requirements for a successful match:

- Attribution-Reporting-Register-Trigger's "trigger_data" must match one of the values provided in the Attribution-Reporting-Register-Source's "trigger_data".
- The site (scheme + eTLD+1) of the top-level page on which the trigger is being registered is either
  - A match to the site of at least one of the destinations specified in the source's associated data.
  - Same-origin with the request that specified the source registration.
- The trigger's filters must match the source's filter data.
- The source’s “trigger_data_matching” setting must result in a match occurring.
- The source's "max_event_level_reports" limit must not have been reached.
- The browser does not replace the successful match with a noised report.

## Report Lifetime on User Device
If a report is triggered and a successful match between attribution sources is found, the browser generates a report based on the source and trigger data. To  anonymize users to the advertisers, reports are sent from the browser to the seller’s server at a delay, which means reports are stored within the browser for a period of time.
### Default Value:
Event source conversion reports are sent by the browser to the ad tech approximately one hour after the event’s expiry.  The default value is 30 days after registration.

Navigation source conversion reports are sent following a more complex schedule of attribution windows. After the navigation, a schedule of built-in reporting windows begins.  By default, navigation reports are sent during one of three windows: 2, 7, or 30 days after registration.  Conversions registered before that deadline are sent at the end of that window.

### Customizable Values:
There are two values that can be used to customize report transmission times available as fields within the Attribution-Reporting-Register-Source header: report windows and expiration values.
#### Report Windows:
Report windows designate  how often reports will be sent.  The fields for customizing these values are:
- event_report_window: A string representing a time in seconds, after which subsequent triggers won't be attributable to this source for the purpose of producing event-level reports (this is called a report window). If not set, the event report window falls back to the "expiry" value.
- event_report_windows: An object representing a series of report windows, starting at "start_time", with reports for this source being delivered after each specified end time in "end_times". This can be used to vary the time of report delivery across multiple reports. If not set, the event report window falls back to the "expiry" value. Properties are as follows:
- "start_time" Optional: A non-negative number specifying the start time for the reporting windows. If not specified, it defaults to 0.
- "end_times": An array of positive numbers specifying end times for subsequent report windows. The values must be increasing, and greater than "start_time".
    
Only one of the fields,  "event_report_window" or "event_report_windows", can be specified.  If both are specified, the source registration will fail.

#### Expiration Values:
The expiration value designates the time after registration that the attribution source is active. This value defaults to 30 days. The field for customizing this value is:

- expiry: A string representing an expiry time in seconds for the attribution source.
The soonest value permitted for report windows and expiration values is 1 day. The latest period permitted is 30 days.

### Reporting Delays
Reports may not be sent exactly at the scheduled dates and times. If the browser isn't running when a report is scheduled to be sent, the report is sent at browser startup. The browser may also decide to delay some of these reports for a random, but short, duration. This duration should be no more than an hour.

## Attribution Reports Data
To send a report, the browser will make a non-credentialed (i.e. without session cookies) secure HTTP POST request to:
```
https://<reporting origin>/.well-known/attribution-reporting/report-event-attribution
```
The report data is included in the request body as a JSON object with the following keys:

 - **Attribution Destination:** the attribution destination set on the source
 - **Source Event ID:** 64-bit event id set on the attribution source
 - **Trigger Data:** Coarse data set in the attribution trigger registration
 - **Report ID:** A UUID string for this report which can be used to prevent double counting
 - **Source Type:** Either "navigation" or "event", indicates whether this source was associated with a navigation.
 - **Randomized Trigger Rate:** Decimal number between 0 and 1 indicating how often noise is applied.
- **Scheduled Report Time:** The number of seconds since the Unix Epoch (1970-01-01T00:00:00Z, ignoring leap seconds) until the browser
   initially scheduled the report to be sent (to avoid noise around
   offline devices reporting late).
