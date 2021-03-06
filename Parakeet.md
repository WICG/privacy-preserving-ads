# PARAKEET

This document is intended as a starting point for engaging the community and standards bodies in developing collaborative solutions fit for standardization.

Feedback is welcome in the form of github issues and via discussions in existing forums currently discussing proposals related to web advertising. Our goal is to make this publication a dynamic document that reflects feedback that we receive. If you have questions about how or where to provide feedback, please contact us at web-ads-privacy@microsoft.com.

## Table of Contents
   * [Introduction](#introduction)
   * [Overview](#overview)
   * [Use Cases](#use-cases)
   * [Scope](#scope)
   * [API flow for ad serving](#api-flow-for-ad-serving)
     * [Interest-Based Ad Targeting](#interest-based-ad-targeting)
     * [Ad Interest Privacy and Anonymization](#ad-interest-privacy-and-anonymization)
     * [Ad Request with Anonymization](#ad-request-with-anonymization)
     * [Potential API shape](#potential-api-shape)
       * [Conversion Measurement](#conversion-measurement)
       * [Data flows](#data-flows)
   * [User Controls](#user-controls)
   * [Key Considerations and Feasibility](#key-considerations-and-feasibility)
   * [On-device vs. Cloud Service for Ad Interest and Anonymization](#on-device-vs-cloud-service-for-ad-interest-and-anonymization)
   * [Privacy Analysis and Targeting](#privacy-analysis-and-targeting)
     * [Contextual Information and Anonymization](#contextual-information-and-anonymization)
     * [Multiple segregated ad requests vs. a single ad request](#multiple-segregated-ad-requests-vs-a-single-ad-request)
     * [Security](#security)
   * [Alternative Solutions](#alternative-solutions)
   * [Open Questions](#open-questions)


## Introduction
At Microsoft, we are committed to fostering a healthy web ecosystem where everyone can thrive – consumers, publishers, advertisers, and platforms alike. Protecting user privacy is foundational to that commitment and is built into Microsoft Edge with features like Tracking Prevention, Microsoft Defender SmartScreen, and InPrivate browsing. We also support an ad-funded web because we don't want to see a day where all quality content has moved behind paywalls, accessible to only those with the financial means.   

Through this proposal, we believe we can substantially improve end-user privacy while retaining the ability for sites to sustain their businesses through ad funding. We propose a new set of APIs that leverage a browser-trusted service to develop a sufficient understanding of user interests and therefore enable effective ad targeting without allowing ad networks to passively track users across the web. This approach removes the need for cross-site identity tracking, enables new privacy enabling methods to support monetization, and maintains ad auction functionality within existing ad tech ecosystems.

Today, we're pleased to further this discussion among the web community with the contribution of one possible approach. We will continue to collaborate with the community to iterate on this and other proposals with the goal of landing on a set of interoperable standards that work in multiple browsers. Together with the web community, we have an opportunity to share ideas, learn from each other, and create a better future for the web.  

## Overview

This proposal defines an internet-hosted service trusted by the browser that assists in user interest inference and anonymization in the ad ecosystem. This service replaces the current model where ad networks store cross-site identifiers for interest-based ad targeting. 

The service will use Private and Anonymized Requests for Ads that Keep Efficacy and Enhance Transparency ("PARAKEET").

**PARAKEET** is a service for anonymizing ad requests and user interest inference support. It has many advantages including strong privacy contracts based on differential privacy and ad request anonymization, user transparency and control of ad interest membership and granularity, monetization that leverages both site context and ad interest information in a unified request. 

The service aims to offer significant privacy improvements with fewer changes (relative to other proposals in this space) required on the part of website owners which will help accelerate adoption in the ad ecosystem. 

This document will explain our proposal at a high level. Future explainers around specific components of PARAKEET will go into more detail. 

At a high level: 

  1. The browser, working together with the browser-provided service, will apply modifications to the ad request before it is sent to the ad network. It will:

      i. Anonymize the context provided by the publisher. 

      ii. Augment the ad request with the browser-provided anonymized user's ad interests, having ensured the request meets privacy requirements around identifiability and user control. 

      iii. Anonymize the user's geographic information and other client-specific context where possible by making information coarser and/or adding randomization to meaningfully reduce the ability to deanonymize the client. 

      iv. Support user interest inference models for advertisers based on the activities on their site. 

      v. Use differential privacy and service-assisted global context to enforce limits on the identifiability of user interest information and contextual signals sent in ad requests.

 2. The ad network will perform ad matching, ranking and auction with contextual and user interest information provided in the privacy-anonymized ad request. 

## Use Cases

Today, a user's interests— potentially represented as segment list memberships or retargeting list memberships— are inferred based on their web activities by ad networks, advertisers, or publishers. 

Publishers reserve locations on their web pages to show ads from ad networks. Requests for these ads are normally sent from the browser to ad networks as part of a user viewing a web page. These requests are frequently augmented with context provided by the publisher to improve the effectiveness of the ad network's ad selection. 

Participating ad networks then run an ad matching/auction engine that combines the publisher's contextual information and user interest information to select an optimal ad to display on the publisher's page.

The advertiser matches an ad with a user based on one or more of the following: the user's activities on the advertiser's site, the user's similarity with the advertiser's current visitors, the user's propensity to convert in relevant categories, and the context provided by the publisher about the page the user is viewing. These are also referred to as retargeting, lookalike targeting, in-market targeting, and contextual targeting. PARAKEET aims to support these use cases. 

   * [Retargeting](https://github.com/w3c/web-advertising/blob/main/support_for_advertising_use_cases.md#retargeting): the targeting of ads based on past user activity. 
   * [Lookalike targeting](https://github.com/w3c/web-advertising/blob/main/support_for_advertising_use_cases.md#lookalike-targeting): the targeting of ads based on the user's similarity to an advertiser's existing customers. 
   * [In-market audience](https://github.com/w3c/web-advertising/blob/main/support_for_advertising_use_cases.md#audience-definition): requires a propensity score that estimates the likelihood the user will click or convert based on their semantic representation. 
   * [Contextual targeting](https://github.com/w3c/web-advertising/blob/main/support_for_advertising_use_cases.md#display-and-target-environment): the targeting of ads based on display, device or other environmental context of the user. 


## Scope

This explainer is scoped to the API and service infrastructure to enable privacy-friendly monetization. Implementations of user control UI and settings are user agent-specific.

The rest of this explainer is organized into three sections: the flow of the API and how it enables ad serving, a discussion of the design and comparisons to existing proposals, and a description of the privacy-preserving techniques and privacy impacts of this proposal. 

## API flow for ad serving

This section explains how ad serving will work end-to-end. The data flows are summarized in this diagram.

<img src="./diagrams/Overallflow.png" alt="High-level dataflow diagram" width="1000"/>

There are three key components: advertiser targeting, anonymized ad requests, and user controls.

### Interest-Based Ad Targeting  

To enable the advertiser to choose the most relevant ad for a specific user and context, an advertiser with the help of DSP (demand side platform) tools will be able to add the user to an ad interest group or share semantic representations, and propagate these to the service using an API similar to that defined by TURTLEDOVE:  
```
const AdInterests = {'origin': 'www.advertiser.com',
                     'business': 'advertiser name'
                     'interests': ['athletic-shoes',...]
                     'representations': [ Model1, Model2 ]
                     'readers': ['first-ad-network.com',
                                 'second-ad-network.com']
                };
navigator.joinAdInterestGroup(AdInterests, 30 * kSecsPerDay);
```

`AdInterests` is composed of the following:
* `origin`: The advertiser domain that is adding the user to a specific interest group. This will be used to restrict the usage of that interest group as well as to improve user transparency.
* `business`: The overall business/enterprise that owns the domain. This is largely for transparency so that a user may know which businesses are tracking them.
* `interests`: A list of ad interests based on current activities or group activities on the domain.
* `representations`: A list of vector representation models supported by the browser and are permitted to encode page content. NLP models such as DSSM, Doc2Vec are example representation models, which encode text to k-dimensional vector, typically k=128 dimensions. Representation models will be trained using differentially private algorithms to avoid encoding user PII information, and the vectors will be further quantized and anonymized to protect user identity. Since these representation models encode semantic information based on recent activities of the user, they are helpful to predict a user's click or conversion propensity for specific ad. These user-level anonymized representation vectors will be added to the ad requests.
* `readers`: A list of ad networks allowed to use ad interests and representations.

The `joinAdInterestGroup()` call will register the targeting information with the browser. The browser and its associated PARAKEET service ensure the information is permissioned to the provided ad network origins. The second parameter in this API indicates how long this ad interest group membership is valid (up to a maximum of 30 days).

This interest group information will be used in a collaborative effort between the browser and service to compute the user's ad interests which are then stored in the browser.

### Ad Interest Privacy and Anonymization
The browser will aggregate the user's ad interests across advertisers in browser storage with access control like namespace and readers. Before using these interests in ad requests, the browser will work with the PARAKEET service to anonymize the user's aggregated ad interests across advertisers. The PARAKEET targeting anonymization service will analyze and process ad interests and features across users, leveraging the broad understanding to create anonymized differentially private ad interest representations per user. The anonymized ad interest vector will be provided back to the user's browser for the browser to store. As shown in the overall flow diagram, the anonymized representation of the user's ad interest will be sent in subsequent ad requests through PARAKEET to ad networks as described in the next section.

Note that we anticipate the browser will transparently provide control to the user for both actual and anonymized ad interests and features, including advertiser namespace and readers. We will provide additional details for user controls in future explainers.

### Ad Request with Anonymization

When the user visits publisher site `myLocalNewspaper.example`, an ad network script on the page creates a [fenced frame](https://github.com/shivanigithub/fenced-frame) and initiates an ad request to `first-ad-network.example`.

The browser will route the request through PARAKEET instead of making a direct connection with `first-ad-network.example`. As part of routing the request, PARAKEET will analyze the privacy cost and conditionally add the user's differentially private ad interests and features to the request with privacy considerations. The service will also anonymize IP, UA, and any potential user-identifying risk parameters to minimize fingerprinting risk while preserving high-level semantics like coarse user location and device classification which are important for effective monetization with a privacy tradeoff. We discuss additional details for differential privacy and modification to ad interest in the following [section](#privacy-analysis-and-targeting). This combined request is then passed to the ad network.

An ad network will have the opportunity to run optimal ad auction-based click and bid models which leverage pertinent contextual information, user ad interests and user features without having access to user identifiers like the user's cookies, IP, or UA string. The ad network will respond with an ad bundle containing an encoded ad click URL which will be rendered in an opaque [fenced frame](https://github.com/shivanigithub/fenced-frame) which does not allow any exchange of information with the page hosting the iframe.

### Potential API shape
The ad request configuration will be created by invoking a JavaScript API in the publisher's page:
```
const adRequestConfig = {
    'proxied-anonymizing-origin': 'https://ad-network.example',
    'ad-properties': {
      orientation: 'landscape',
      size: 'medium',
      slot: 'div-xyz-abc',
      lang: 'en-us',
      adtype: 'image/native'
    },
    'publisher-code':'10931',
    'publisher-ad-unit': 'publisher_ad_location_1',
    'targeting': {
      'interests': ['music', 'sports']
      },
      'geolocation': '[41.5, -81.7]'
    },
    'anonymized-proxied-signals': ['coarse-geolocation', 'coarse-ua', 'targeting', 'user-ad-interests']
    'fallback-source': 'https://ad-network.example/fallback-for-user-agents-that-do-not-support-proxied-request'
};

const adRequestPromise = navigator.createAdRequest(adRequestConfig);
```
The returned `adRequestPromise` promise is _opaque_ and cannot be inspected or updated by the publisher page. The promise is then passed to a [Fenced Frame](https://github.com/shivanigithub/fenced-frame) as an [opaque source](https://github.com/shivanigithub/fenced-frame/blob/master/OpaqueSrc.md) which in turn processes the request and renders the returned ad.

In this example, the meanings of the ad request configuration parameters are:
* `proxied-anonymizing-origin`: The origin that the anonymizing service request the ad bundle from. A .well-known path, e.g. /.well-known/ad-request, will be queried by the service.
* `ad-properties`: A set of properties whose names and values map to a well-known list of supported values and help inform the ad network of what type of ad to serve.
* `publisher-code`: The number `10931` represents a specific publisher's identity registered with the ad network.
* `publisher-ad-unit`: The string `publisher_ad_location_1` represents an ad unit/vertical that the publisher has registered with the ad network.
* `targeting`: Contextual targeting information for the ad. A potential interest taxonomy for publisher context could be [IAB's taxonomy](https://www.iab.com/guidelines/audience-taxonomy/).
   * `geolocation`: Geolocation info that the web site is aware of. For example, if the user is searching for travel information, their current device's approximate location may be less relevant than the location they are planning travel for.
* `anonymized-proxied-signals`: Specifies what information should be added to the ad request by the anonymizing request service:
   * `coarse-geolocation`: Geolocation info that is coarse enough to ensure that many users send the same geolocation signal. If present, it will use the value of the `targeting` attribute's `geolocation` value (making it more coarse as needed). If a value was not provided, it will send a location value based on signals sourced from the device's OS location API or via a reverse IP lookup.
   * `coarse-ua`: UA information that maps to the browser's brand and version.
   * `targeting`: The targeting information provided by the `targeting` attribute.
   * `user-ad-interests`: Ad interest signals previously determined and set by the ad network, including when they were previously on a different site.
 * `fallback-source`: If the UA doesn't support the anonymized ad request flow, either because of a global decision, a local user decision, or due to an infrastructure outage, it will fall back to loading via the URL in this value.

The service can append user ad interests to the resulting request:

```
user-ad-interests=[ad network-specific interests the browser and service maintain]
```

In this example, assuming the user ad interests are appended, the service would end up making an ad bundle request to:
```
https://ad-network.example/.well-known/ad-bundles?coarse-geolocation=47.66,-122.14&publisher-code=10931&publisher-ad-unit=cars&targeting=[info in targeting attribute]&user-ad-interests=[ad network-specific interests the browser and service maintain]
```

If the full set of information that would be carried by the service ads is too unique (as determined by having a minimum number of users' browsers trying to request an ad with the same set of signals within some reasonable time period), the service will drop the user-ad-interests attribute entirely and pass along the request using the information provided directly by the page (i.e., all of the information in the URL could have been generated by the site and loaded via a normal iframe).

#### Conversion Measurement
These are some early thoughts about how a trusted service, such as PARAKEET, can incorporate conversion measurement and reporting on the web. 

When a user clicks on an ad, multiple involved parties such as the ad network and advertiser want to be able to track that click to understand ad campaign performance metrics such as conversion rates vs. impressions, value of conversion, publishers that lead to optimal conversion rates, users that are likely to convert, etc. Some proposals have been made, such as [Private Click Measurement](https://privacycg.github.io/private-click-measurement/) and [Click Through Conversion Measurement Event-Level API](https://github.com/WICG/conversion-measurement-api), to reduce the joinability of click events cross-party via techniques such as constraints on click-related data entropy, noise & local differential privacy, random time delays, and throttles. Additionally, there are proposals for a [Multi-Browser Aggregation Service](https://github.com/WICG/conversion-measurement-api/blob/master/SERVICE.md) that provides data and analytics to sites about conversion flow in a more privacy protective manner.

We are considering combining those approaches by leveraging the trusted relationship proposed by the PARAKEET service to enable increased fidelity of conversion metrics while reducing user identifiability. One potential approach is for the PARAKEET service to proxy communication between the browser and related parties during a click event, reducing the ability for user to be uniquely identified based on data such as IP address, UA, etc. Additionally, PARAKEET could provide party-specific clickIDs in the click event flow and an endpoint for ad networks and advertisers to report back detailed information on the conversion progress via those clickIDs. This detailed understanding, at a global scale, would allow the service to leverage techniques such as global differential privacy for generating privacy protecting reports for the involved advertiser, ad networks, and publishers while still improving user privacy.

#### Data flows
It is important to note that ad serving is enabled with privacy-preserving anonymity. Refer to the call sequence and high-level interaction image for dataflow and integration. These diagrams are for high-level illustration purposes and do not comprehensively cover every aspect of the proposal.

![AdRequestClick Call Sequence](./diagrams/sequenceDiagram.png)

## User Controls

In this proposal, the browser can provide users with control to view and manage ad interest group membership as well as ad serving and clicks. The browser will offer opt-out controls to user at various granularities (i.e., ad category, advertiser, and ad network), implemented where necessary via API calls to the PARAKEET service. The browser may allow users to delete membership in specific interest groups and restrict specific advertisers from adding them to interest groups. The browser may also show aggregated statistics of user populations in each pertinent targeting to provide users insight into anonymization. The actual set of user controls and their implementation is browser specific and outside the scope of this proposal. The specific controls listed here are speculative and intended to encourage further thought. 

## Key Considerations and Feasibility

The primary focus of this proposal is to describe an intermediate service that enables interaction between an advertiser, a publisher website, and an ad network while providing the user powerful data oversight and control mechanisms. This proposal is solely focused on browser-based monetization. While some aspects of this proposal may be useful in non-browser contexts, we consider those to be out of scope for this proposal.  This change to the current web monetization flows is both important and required to retain the efficacy of monetization and ad auctions while meeting users' privacy needs. PARAKEET targets an incremental change that avoids large impact to current auction, bidding functions and delivery systems while still meeting both privacy and web monetization needs.

The cost of running PARAKEET is an important aspect to discuss. Enabling a monetization service whose costs to run are shared by publishers and/or advertisers is not unique and is similar to existing mechanisms that use ad exchange fees and SSP (supply-side platform) and DSP (demand-side platform) fees. We believe this proposal can be funded in a similar manner.

Performance impacts on users' devices is also an important consideration. In particular, if some aspect of user ad interest aggregation and/or anonymization is performed on the users' devices, the CPU, memory, disk, and resulting power impacts could be significant. Similarly, network traffic for data flows leaving the device should be considered, particularly for scenarios where limited upstream bandwidth is available. The overall impact could be especially significant if some aspects of this work includes machine learning running on users' devices. All of these aspects must be considered when selecting how user ad interests are processed and anonymized.

## On-device vs. Cloud Service for Ad Interest and Anonymization

This proposal describes a "service" that serves monetization scenarios in a privacy-serving way in the cloud. To protect user privacy, the privacy risk analysis needs to leverage global understanding about the distribution of ad interests and the ability to correlate with user identity. Our proposal leverages a cloud service that enables the browser to mitigate limitations for compute and memory usage on the device.

## Privacy Analysis and Targeting

To analyze the protection offered by differential privacy, let us assume that there are __U__ users of a given browser. Ad interests for each individual user _u_ can be represented as a binary vector of dimensions _N_. We share the ad interest vector for the user _u_ in each ad request while maintaining reasonable privacy guarantees. We propose to cluster all user ad interest vectors into _K_ clusters with differential privacy. At ad request time, for a user, we propose to share the nearest cluster centroid with probability _p_ and a random cluster centroid with probability _(1-p)/(K-1)_. It's a simple yet effective solution and can be shown to satisfy Differential Privacy for a given user's ad interest vectors with

![equation](http://www.sciweavers.org/tex2img.php?eq=\epsilon%3Dln\frac{p%28K-1%29}{1-p}&bc=White&fc=Black&im=jpg&fs=12&ff=arev&edit=)

The following are important considerations in the differential privacy analysis:
* Ensuring that each ad interest or targeting dimension is not microtargeted is not sufficient. For example, one can adversarially encode identity for every individual on the earth using 23 binary ad interests without microtargeting and exchange it with other parties.
* There could be additional alternate approaches for clustering users within time epoch and/or selection of alternate cluster centroid based on distance or likelihood measures. We would rather focus this proposal on system design and intend to follow up with additional algorithms and formal analysis of same as separate discussions.
* Separating contextual ad requests and interest-based ad requests is a weak form of privacy protection, if any. Ad requests with multiple ad interests without privacy anonymization can be used to exchange user identity between multiple advertisers. Privacy parameters need to be analyzed for all requests simultaneously even though they are sent separately at different times.
* Contextual ad requests without any privacy anonymization exchange user identity between a publisher and an ad network. Often, an entity partners with an ad network as both publisher and advertiser to be able to join data on user identity.

### Contextual Information and Anonymization

Ad network leverages various contextual signals for content-based ad selection or [bidding optimization for ad interest-based ads](https://support.google.com/google-ads/answer/7065882#signals). These signals include page category, keywords, location intent, language, device signals (browser, operating system), placement to name few. We propose to reduce granularities of contextual signals to ensure privacy of the user and reduce linkablity of activities. 
* Page content signals: We propose to reduce page category and keyword signal granularity based on user distribution across these category and keyword dimensions during a fixed length time interval to limit linkability to a specific user. The service will randomize or drop certain category or keyword values (similar to the ad interest proposal) to improve privacy. We propose to remove page URL and page title from ad request. Websites can work with SSP or ad network prior to get page category and keywords to pass in an ad request.
* Location intent: Location intent is another important signal for ad networks to serve relevant ads and honor advertiser targeting restrictions. Websites can pass explicit location intent in ad request. The anonymization service will maintain user population at various location granularities (country, state, county, city, zipcode, lat+long) for the last 1 minute and reduce granularity in outgoing request to at least 10K+ users. This will also be consistent with IP anonymization, descriptively selecting random active IP from anonymized location granularity.

* Device signals: We think that UA truncation and client hint are reasonable solutions for anonymization device signals. 

We understand that this significant change compared to current contextual ad requests. However, we believe that contextual signals have similar privacy sensitivity as ad interest; thus, change is necessary to avoid user identity exchange across websites and ad networks.

### Multiple segregated ad requests vs. a single ad request

The key difference between previously proposed approaches such as TURTLEDOVE and PARAKEET is multiple ad requests with segregated information vs. a combined anonymized ad request. Multiple fragmented ad requests are an interesting primitive. However, that approach requires simplified aggregate functions, such as the auction, to be client-side. In most ads systems, user and contextual information are used in multiple stages, such as ad relevance computation, click and conversion propensity predictions, policy controls, creative optimization, bid models, and pricing. Incorporating each of these capabilities in client-side aggregation methods is challenging and an oversimplification. We propose to provide non-fragmented, anonymized ad requests that allow ad networks to perform key functionality while restricting request parameters via differential privacy. We propose to provide user transparency regarding the ad interest and contextual information that could be sent in ad requests and to allow the user to control the information. 

A privacy cost analysis of these two different proposals should be compared extensively, looking at benefits and limitations for privacy, monetization, cost, and adoption simplicity. 

### Security

**Threat analysis**

 - ***Repeated ad requests revealing user's interests***

   This proposal combines contextual signals coming from the page and interest group information derived from other activity on potentially unrelated sites.
        
   An ad network or advertiser colluding with a site (N.B. this includes scenarios where the site unknowingly colludes due to script it runs from the ad network) could attempt to generate an ad request with contextual signals that are unique enough to map to a single or small set of users.
        
   When the ad request is made, it could potentially extract out the interest group information and associate it with a well-known user ID on the site which previously had no knowledge of those interest groups, achieving a cross-site data transfer.

   To mitigate that risk, this proposal describes various anonymization techniques such as determining the level of uniqueness of an ad request, removing random pieces of information in the request, and injecting noise into the signals included in the request. If multiple ad requests from the same client rotate contextual signals but retain the same interest group information, even with noise applied to individual requests, an adversary could potentially use request timing information to determine the true interests of an individual user.

 - ***Timing correlation***

   As described in the previous threat, this proposal describes calculating uniqueness of individual ad requests using based on some sliding time window. Given ad requests are made immediately in this flow, it's likely even with a small time window that an adversary could associate when it made an ad request on a client with when it sees the anonymized request coming from the PARAKEET service.

   Potential solutions such as injecting a random delay into an ad request to ensure non-deterministic request ordering come with significant downsides. More exploration is needed on what time window and client count thresholds would be viable.

 - ***Contextual signal stuffing attack***

   An adversary could potentially get around global uniqueness constraints by serving ads to many different clients with the same set of contextual signals to increase the odds that a uniqueness threshold has been passed. Once it believes the request no longer looks unique to the service, it could stop the use of those signals in all other clients and make an ad request from one last client of interest. It could then look at the last ad request made with those signals and extract the interest group information associated with it to the user's identity on that site.

   Potential solutions might be both technical and policy-based. On the technical side, a given origin could be limited on how many unique contextual signals it sends within some time range. On the policy side, access to the PARAKEET service might be conditioned on not using such a technique.

 - ***Trust in the PARAKEET service***

   The browser and its user put trust in the PARAKEET service to ensure data flows only happen when they are not privacy-revealing to ad networks.
        
   Some users may not be comfortable with the data shared with the service; reasonable user controls that allow users to control the data flows is likely desirable.

   It's critical that maintainers of such a service follow best security and privacy practices to ensure unintentional data leakages do not happen. Technical solutions to reduce the visibility the service has into individual user data should be explored; multi-party computation schemes are of particular interest and will continue to be explored.

## Alternative Solutions
Proposals to address web advertising use cases are many. The Web Advertising Business Group's repo has a [summary of various use cases and current proposals](https://github.com/w3c/web-advertising/blob/master/support_for_advertising_use_cases.md) that address each of them.

This proposal covers some of the same use cases as existing proposals. Some try to solve the exact same scenario in different way while some are mostly complementary. We will continue to collaborate with the community on this and other proposals with the goal of landing on a set of interoperable standards that work in multiple browsers.

The proposals we provide comparisons to below is not intended to be exhaustive. Feedback is welcome on what other proposals would be worth comparing and contrasting.

 - ***[TURTLEDOVE](https://github.com/WICG/turtledove)***:

   As described earlier in this document, the most significant difference between SPARROW and TURTLEDOVE is that TURTLEDOVE completely separates contextual and interest group signals by making two separate uncorrelated requests.

   The TURTLEDOVE set of proposals continues to evolve. The Google Chrome team has a specific prototype implementation that combines ideas from those proposals called [FLEDGE](https://github.com/WICG/turtledove/blob/master/FLEDGE.md).
   
   FLEDGE adds trusted server concepts in the following ways:
   * A pre-seeded service that allows the browser to get updated, real-time context such as information about remaining ad campaign budgets. The service is supposed to limit itself to answering queries without side effects. For example, it does no event-level logging and doesn't make a request to an ad network as a result of the query.
   
     This concept draws inspiration from [Dovekey](https://github.com/google/ads-privacy/tree/master/proposals/dovekey), which we provide a more direct comparison to below.
   * A speculative future modification that ad bundles might get routed/proxied through a trusted CDN.
   * Reporting will use a trusted server in some way, perhaps using a service similar to the one called out in the [Trusted Browser Aggregation Service Explainer](https://github.com/WICG/conversion-measurement-api/blob/master/SERVICE.md).
  
    PARAKEET is similar to FLEDGE in that it also proposes a trusted server to mediate ad requests, fetch ad bundles, and provide measurement capabilities. PARAKEET envisions the service being trusted to handle more complex contracts during the ad serving flow to enable both strong levels of privacy while retaining the ability to serve relevant ads by having more direct interactions with the SSP.
  
    As a result of the greater level of trust in the service, we currently envision the service as being chosen by the UA (browser vendor) rather than federated to multiple entities via some external certification mechanism. All contracts between the PARAKEET service and SSPs will be defined in the open in order to allow for independent analysis and feedback about the strength of the proposed privacy protections.

  Also relevant for comparison purposes:

  - The [Augury API for TURTLEDOVE](https://github.com/google/ads-privacy/tree/master/proposals/augury) proposal adds a new primitive that allows a contextual ad request to provide additional context about interest-group based ads that may be of interest.

     This provides a mechanism for considering both contextual and interest group signals at auction time. However, this is slightly more limited since it requires predicting which candidates will be useful, while PARAKEET allows for a more granular selection.

 - ***[SPARROW](https://github.com/WICG/sparrow)***:

   The gatekeeper service in SPARROW shares many similarities with the service proposed in PARAKEET in terms of data flows between the client and service.
   
   SPARROW is similar to TURTLEDOVE since the contextual and interest-group based ads are still requested separately. However, in TURTLEDOVE the auction happens on the client,  while in SPARROW the gatekeeper service is used to estimate bids and perform the final ad auction.
   
   SPARROW's similarity with PARAKEET  is that the interest group ad request is made as part of the ad serving flow instead of being fetched ahead of time. The primary difference is that PARAKEET allows ad networks to host retrieval, auction, and bidding model functionality within an ad network's service, while the gatekeeper model requires the ad network to share the bidding and auction functionality with the gatekeeper service.

   Concerns around the level of trust and auditability of the service are generally the same between SPARROW and this proposal.
   
 - ***[Dovekey](https://github.com/google/ads-privacy/tree/master/proposals/dovekey)***:

   Dovekey involves a mediator service, similar to SPARROW and PARAKEET, to allow both contextual and interest group signals to be considered during an ad auction and to solve other critical use cases such as budgeting.
   
   In Dovekey, the SSP needs to preemptively inject keys into the mediator key-value service where effectiveness is based on how well it can predict contextual signal and interest group combinations within some budget of keys.

   Since the combined signals used during the auction don't go to the SSP, it doesn't get a direct opportunity to extract knowledge about the client's interest groups. A potential risk in Dovekey's approach is that the actual creative ad fetch could reveal the combined information via a timing attack (which could, in turn, potentially be mitigated by having the KV server pre-fetch ad bundles). In contrast, PARAKEET has unique constraints that reduce the risk; a more complex Dovekey KV server could potentially add privacy thresholds as well.

   In both Dovekey and PARAKEET, there is likely some level of trust placed in the KV server. That proposal calls out potential options for 2-party computation and private information retrieval; we will continue to evaluate refinements to PARAKEET to reduce the level of trust that the user must place in the service.

## Open Questions

[Open a new issue](https://github.com/WICG/privacy-preserving-ads/issues/new?labels=PARAKEET&template=parakeet.md&title=%5BPARAKEET%5D+%3CTITLE+HERE%3E)

See open GitHub Issues: <a href="https://github.com/WICG/privacy-preserving-ads/labels/PARAKEET">
    ![GitHub issues by-label](https://img.shields.io/github/issues/WICG/privacy-preserving-ads/labels/PARAKEET?label=issues)</a> |
    
