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
| Interest Groups | Partitioned by domain everywher | Partitioned by domain on disk and in transit, merged in trusted/transient/opaque env. |
| Privacy constraint approaches | DP, k-anonymity, single domain context | DP, K |
| Multi-slot auctions - (Competitive Exclusion, Page Caps, Roadblocking) | Not fully supported due to scoreAd limitations.| Allows for coordinated placements via multi-tag support in scoreAds(), allows for competitive exclusion, page caps, roadblocking. |
| Multi-size | Not fully supported due to `requestedSize` limitations. | Supported with `requestedSizes`and k-anon requirement for `renderURL` X `size`. |
| Creative selection | Static, must declare at IG creation/update time | Dynamic |
| TEE requirements | Public cloud | Public cloud and, depending on risk analysis potentially other locations (e.g. see the [UK's Cloud security guidance](https://www.ncsc.gov.uk/collection/cloud/the-cloud-security-principles) for potential approaches for establishing safety). |
| Attribution | [Attribution Reporting API (ARA)](https://developer.chrome.com/en/docs/privacy-sandbox/attribution-reporting/) | ARA with modifications for better parity with CPA billing. |
| Operations | Browser and Ad Tech share  critical infrastructure such as k-anon | Ad tech takes control, no shared infrastructure services. |

