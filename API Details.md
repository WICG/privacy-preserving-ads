# Ad Selection API details

This document describes the proposed API for the Ad Selection API proposal.The Ad Selection API aims to have a common API surface area with other similar proposals targeting the same use cases (i.e., the Protected Audience API) with the hope of requiring a lower cognitive load for comparing and contrasting proposals as well as to ease experimentation and adoption by web developers. You can see concepts and primitives referenced here described in the [ad selection overview](Ad%20Selection%20Overview.md).

### API shape
The Ad Selection API aims to maximize syntactic compatibility with the [Protected Audience API](https://github.com/WICG/turtledove/blob/main/FLEDGE.md) to help ease industry adoption of various proposals. Therefore,  where possible, the same primitives will be available. Examples include`navigator.joinAdInterestGroup()`, `navigator.leaveAdInterestGroup()`,  `navigator.getInterestGroupAdAuctionData()`, and `navigator.runAdAuction()`. However, they may function differently and/or provide additional functionality to protect users' privacy and/or increase utility. We strive to make any differences easy to understand and unlikely to create user-visible site compatibility issues.

### On-device vs. server auction
Purely on-device auctions are a promising concept; however, we currently believe there are considerable downsides.

For example, they allow for the observation of auction logic between competitors and shift potentially significant computing onto users' machines which forces an undesirable tradeoff between efficacy and performance. With recent advances in confidential computing, we believe leveraging Trusted Execution Environments (TEEs) for server-side computation for auctions can be done safely and securely. This approach will lead to better outcomes by making managing the cost and complexity of running ad auctions an ad tech server cost consideration rather than something that gets offloaded and distributed to client devices.

The TEE concept allows us to ensure that execution can be performed in a secure manner. Even the operator of the server cannot see into the opaque box and, while they can input business logic to inform the creative selection process, their logic is run in a sandbox that applies constraints that have a goal of preventing private information from being unintentionally leaked outside of the environment. All resulting outputs, such as ad/creative bundle URLs, are further checked against k-anonymity thresholds to minimize the ability to do microtargeting or leak personal information.

In summary, the Ad Selection API requires the usage of bidding and auction TEE images by SSP and DSP participants. Images will be made available during public previews for easy evaluation via deployment in environments supporting TEEs such as Azure Confidential Compute.

### 1.0 Interest-based ad targeting
#### 1.1 Joining interest groups
To enable the advertiser to choose the most relevant ad for a specific user and context, an advertiser, likely using the help of demand side platform (DSP) tools, will be able to add the user to an ad interest group or share semantic representations, and propagate these to the service using an API similar to that defined by the Protected Audience API:

```javascript
const myGroup = {
  'owner': 'https://www.example-dsp.site',
  'name': 'womens-running-shoes',
  'priority': 0.0,
  'priorityVector': {
    'signal1': 2,
    'signal2': -3.5,
    ...
  }
  'prioritySignalsOverrides': {
    'signal1': 4.5,
    'signal2': 0,
    ...
  }
  'enableBiddingSignalsPrioritization' : true,
  'biddingLogicURL': ...,
  'biddingWasmHelperURL': ...,
  'updateURL': ...,
  'executionMode': ...,
  'trustedBiddingSignalsURL': ...,
  'trustedBiddingSignalsKeys': ['key1', 'key2'],
  'userBiddingSignals': {...}
};
const joinPromise = navigator.joinAdInterestGroup(myGroup, 30 * kSecsPerDay);
```

The API allows data that would traditionally be collected and stored server side and referenced/looked up via the use of third-party cookies to instead be stored locally within  the user's browser profile. This shifts the data into the control of the user where they can more easily and confidently see what data is collected and used, provides control to delete or opt out, and allows the browser to protect the user by enforcing constraints on the data uniqueness (to prevent microtargeting or hidden PII) as well as determining how and when the data can be safely used.

Additionally, there is a complementary `navigator.leaveAdInterestGroup(myGroup)` API and embedded browser controls to manage this data. See additional information at [Protected Audiences - Browsers Record Interest Groups](https://github.com/WICG/turtledove/blob/main/FLEDGE.md#1-browsers-record-interest-groups).

### 2.0 Ad auction/selection
#### 2.1 Starting a server auction
In order to start selecting an ad via an ad auction, a request must be made in a similar manner as described in [Protected Audiences - Bidding & Auction API](https://github.com/WICG/turtledove/blob/main/FLEDGE_browser_bidding_and_auction_API.md).

##### Get the encrypted auction request
The `navigator.getInterestGroupAdAuctionData(AdAuctionDataConfig)`API will allow the requestor to receive an **encrypted auction request** blob that cannot be directly observed by the website, ad-tech, or other third party. If a user has opted out or deleted interest groups this API will still return a blob that will simply contain no Interest Groups; this will not be directly observable or possible to identify or target users due to this choice.

#### 2.2 Perform server-side auction
The encrypted auction request can be sent using the [Fetch API](https://fetch.spec.whatwg.org/) to the supply-side platform (SSP) to perform the associated server-side auction. This can happen in parallel to any real-time bidding (RTB) decisions with available contextual signals. It is important to note that while the auction request is sent to an untrusted seller provided server, it is strongly encrypted and not observable by this or any intermediary party.

The seller must pass this encrypted object to their seller TEE instance which will handle performing the auction, getting bids from relevant DSPs, executing SSP/DSP business logic in a secure sandbox and ultimately providing an encrypted auction response that **only the browser can observe**. In short, the TEE environment ensures that the auction request can only be observed in isolation running trusted code from the browser vendor in an environment that can't be observed by administrators or outside parties and is only shared among other TEEs running code that is trusted by the user agent. Additionally, any resulting output is encrypted so that only the user agent can view it and additionally enforce additional privacy constraints before deciding if the results are safe to be used from a privacy perspective.

```javascript
navigator.getInterestGroupAdAuctionData({
  'seller': 'https://seller.site',
  'coordinator': 'azure'
}).then(encryptedRequest => {
    fetch("https://seller.site/seller-side-auction", {
      method: "PUT",
      body: encryptedRequest,
      adAuctionHeaders: true
    }).then(response => {
       // Run navigator.runAdAuction to resolve/display winning creatives privately.
    });
});
```

When the `adAuctionHeaders` parameter is specified as a Fetch request the browser will send a new Request header `Sec-Auction-Platform-Support`with a list of supported platforms/versions to indicate what type of auction request and platform is being made. This will help allow sellers to distinguish the type of auction request being made and allow for diversification and competition in this space as other proposals and mechanisms are developed. This header may include [GREASEd](https://datatracker.ietf.org/doc/html/rfc8701) value.

```http
Sec-Auction-Platform-Support: "Microsoft Edge";min-version="1.0.0.1", "Not;A=Brand";min-version="8.0.0.0"
```

##### Serverside auction time
The semantics of how sellers structure their auction request are largely up to them. The only requirement is that the provided encryptedRequest payload be provided to the associated seller front end TEE service and that the resulting **encrypted auction response** be returned to browser with a corresponding `Ad-Auction-Result` response header for correct validation and identification.

Details of what happens during the secure and private server-side auction can be found in more details in a [life of an ad request](Life%20of%20an%20Ad%20Request.md) and related documents. At a high level, the primary additions that can be expected with the Ad Selection API and auction are that DSPs (buyers) can dynamically inject additional creatives and bids at auction time; support for traditional ad server features through multi-tag auctions and multi-size tags; and validation and enforcement of k-anonymity thresholds has been incorporated into the server auction flow. We believe the proximity to the auction logic for k-anon checks allows for quicker response, reducing auction latency, and improves the accuracy of this protection without requiring individual clients to make a choice between accuracy and performance.

#### 2.3 Handling the server response
Once an encrypted auction response is received by the browser it will validate the contents and ensure that any proposed winning creatives are indeed sufficiently anonymous. In order to consistently apply these privacy checks the response can be passed as the `serverResponse` property to `navigator.runAdAuction()` similarly to [Protected Audiences - Complete auction in browser](https://github.com/WICG/turtledove/blob/main/FLEDGE_browser_bidding_and_auction_API.md#step-4-complete-auction-in-browser).

```javascript
const auctionResultPromise = navigator.runAdAuction({
  'seller': 'https://seller.site,
  'requestId': someUniqueID',
  'serverResponse': encryptedAuctionResponseBlob,
}).then(winningUrn? => {
  if(winningUrn) {
     // inject winning creative into DOM
  }
});
```
The primary difference here is that any response will have already been validated for k-anonymity during the server auction and **no client-side/local auction will be performed** (the `interestGroupBuyers` property will be ignored). The serverResponse property must be provided to complete the auction.

The resulting opaque URL, if present, can then be used as the src property to a [Fenced Frame](https://github.com/WICG/fenced-frame ) or other compatible frame to render the winning creative.

**Note: It is possible for no winning creative to be selected and, as with the Protected Audience API proposal, rendering within fenced frames will initially not be required.**

### 3.0 Reporting
#### 3.1 Event-level win reporting on render
Once the winning ad has rendered in its frame, the seller and the winning buyer each have an opportunity to perform logging and reporting on the auction outcome. The reporting URLs are generated in the [Auction service] (https://github.com/privacysandbox/fledge-docs/blob/main/bidding_auction_services_system_design.md#auction-service) using the `reportResult()` function provided by the seller and `reportWin()`  function provided by the buyer. Spec for `reportResult()` and `reportWin()`can be found [here](https://github.com/privacysandbox/fledge-docs/blob/main/bidding_auction_event_level_reporting.md#the-reportresult-specification). These reporting URLs are returned to the client as part of the encrypted auction response from the server. Once the winning Ad is rendered, these reporting URLs are pinged by the client.

#### 3.2 Other ad events via fenced frame reporting API
Ads often need to report on events that happen once the ad is rendered. An example would be reporting on whether an ad became viewable on-screen. Ad techs can register URLs that correspond to such events or beacons when `reportResult()` and `reportWin()` are run. The beacons can be registered by calling the `registerAdBeacon()` function, which will be a part of the executable code in Roma on the Auction Service.
For example:
```javascript
reportWin(auctionSignals, perBuyerSignals, sellerSignals, buyerReportingMetadata) {
  registerAdBeacon({"click", clickUrl,"view", viewUrl});
  sendReportTo(reportWinUrl);
  return;
}
```
These registered ad beacon URLs are also returned as part of the encrypted auction response. The fenced frame in which the Ad is rendered can invoke the `reportEvent` API to tell the browser to send a beacon with event data to the registered URL that matches the event type. More details on the `reportEvent` API can be found [here]( https://github.com/WICG/turtledove/blob/main/Fenced_Frames_Ads_Reporting.md#reportevent).
#### 3.3 Support for attribution source registration in fenced frames
##### Goals
- While fenced frames still have unrestricted network access and the Ad Selection API supports event-level reporting, the solution below takes advantage of the `registerAdBeacon`/`reportEvent` information flow to enable [registering attribution sources](https://github.com/WICG/attribution-reporting-api/blob/main/EVENT.md#registering-attribution-sources). [ARA attribution triggering](https://github.com/WICG/attribution-reporting-api/blob/main/EVENT.md#triggering-attribution) is unchanged for registered Ad Selection impressions.
- Improve the ergonomics of triggering ad beacons based on clicks.


##### registerAdBeacon
The `reportResult` and `reportWin` code on the auction service will be able to register an event called `reserved.top_navigation` via `registerAdBeacon`.

```javascript
registerAdBeacon({
 'reserved.top_navigation': 'https://adtech.example/click?buyer_event_id=123',
});
```

The new event, if registered, implies that an automatic beacon will be sent by the browser to the registered URL when a top-level navigation is invoked from within the fenced frame and the navigation was preceded by a call to [window.fence.setReportEventDataForAutomaticBeacons](#api-to-populate-event-data-for-reservedtop_navigation). This will impact top-level navigation initiated from the fenced frame in the same tab (via [unfencedTop target](https://github.com/WICG/fenced-frame/blob/master/explainer/integration_with_web_platform.md#top-level-navigation)) or in a different tab. Note that this beacon is gated on a transient user activation.

##### reportEvent
The beacons that are generated from a `reportEvent` invocation or via the automatic `reserved.top_navigation` event will now be automatically eligible for attribution, i.e. the browser appends the `Attribution-Reporting-Eligible` HTTP request header. The beacon responses can then register attribution sources as usual, as described [here](https://github.com/WICG/attribution-reporting-api/blob/main/EVENT.md#registering-attribution-sources).

More details regarding this flow can be found [here](https://github.com/WICG/turtledove/blob/main/Fenced_Frames_Ads_Reporting.md#support-for-attribution-reporting).


