# API difference highlights
Ad Selection API is a privacy-preserving ads (PPA) proposal that largely aligns on API surface area with similar proposals such as Google Chrome's Protected Audience API. It adopts core privacy-protecting approaches such as differential privacy and k-anonymity, but:
- Allows transient processing of bidding signals across domains in trusted and opaque environments.
- Proposes initially supporting only Trusted Execution Environment (TEE)-based solutions to enable safer dynamic operations and greater ad tech ownership which we believe will increase the chances of a successful ecosystem migration to privacy-preserving ad serving.

We intend to work with the web standards community, including the [Private Advertising Technology Community Group](https://patcg.github.io/) (PATCG), and the broader ecosystem to iterate, find common ground, and work towards standards that will create a better future for the web.
Ad Selection API is currently largely syntactically and feature compatible with the Protected Audience API while allowing additional functionality. We see the core privacy model focusing on:

- Differential privacy
- K-anonymity
- User control
To prevent the API from enabling persistent cross-site profile building of users, cross-domain signals must not be joinable in untrusted or persistent environments. We will begin with a TEE-only solution to keep operational excellence and competitiveness with ad techs. Creatives can be dynamically selected.
We look forward to extensive public engagement with the industry, PATCG, and other participants.

See the [_Ad Selection Overview_ document](Ad%20Selection%20Overview.md) for more detail.

This table documents known differences at the time of publication. As this proposal and others evolve, we expect to update it accordingly.

|  |Protected Audience API | Ad Selection API |
| - | - | - |
| Auction location | TEE or on-device | TEE Only |
| Interest Groups | Partitioned by domain everywhere | Partitioned by domain on disk and in transit, merged in trusted/transient/opaque env. |
| Privacy constraint approaches  | DP, k-anonymity, single domain context | DP, K-anonymity. |
| Creative selection | Static, must declare at IG creation/update time | Dynamic. Dynamic `render_url` and dynamic interest group names can be generated in moment of bidding. New lookup algos will be available in Key/Value service to provide more effective ways to do selection. |
| Data available for Bidding|BuyerSignals and separate InterestGroups connected with `TrustedSignals` from KV | `BuyerSignals`, all InterestGroups with `TrustedSignals` owned by Buyer, (optional) dynamic TrustedSignals from Key/Value Service through new hook in bidding (key for lookup is dynamic). |
| TEE requirements | Public cloud | Public cloud and, depending on risk analysis potentially other locations (e.g. see the [UK's Cloud security guidance](https://www.ncsc.gov.uk/collection/cloud/the-cloud-security-principles) for potential approaches for establishing safety). |
| Attribution | [Attribution Reporting API (ARA)](https://developer.chrome.com/en/docs/privacy-sandbox/attribution-reporting/) | ARA with modifications for better parity with CPA billing. |
| Operations | Browser and Ad Tech share  critical infrastructure such as k-anon | Ad tech takes control, no shared infrastructure services. |

Some of the features that are highlighted will require changes in browser API, in B&A code or some other technical implementation. All such changes are collected in the table below and are explained in more detail in other docs:

| New logic | Description |
| - | - |
| New Bidding’s hook – FetchAdditionalSignals. | New hook for looking up additional signals will be available from the Bidding worklet. </p>More details - [New hook logic]( Bidding%20Service%20functionality.md#4). |
| Changes in input and output of bidding | At the moment of bidding, Buyer will have access to all InterestGroups owned by Buyer. <br>Bidding can return dynamic `render_url` and InterestGroup as a winner. </p>More details - [New bidding functionality](Bidding%20Service%20functionality.md#L98). |
| New logic in Key/Value service | Key/Value service will support new algos that can provide more effective way for ad selection process (e.g., DiskANN algorithm). </p>More details - [Ad Candidate Real-time Selection](Ad%20Candidate%20Real-time%20Selection.md). |
| Azure support | Ad Selection API can be deployed in Azure. </p> Details will be added soon. |
| K-anon service | K-anon – new service that need to be deployed by Buyer that will be used for calculation of k-anonymity counters.  </p> Details will be added soon. |