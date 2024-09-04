# Why privacy-preserving advertising?

Over the last four years the [Private Advertising Technology Community Group](https://patcg.github.io/), [Web Incubator Community Group](https://github.com/WICG), and other communities have worked together to develop and enhance privacy-preserving advertising (PPA) proposals and implementations that demonstrate strong privacy guarantees for users can be achieved without sacrificing the ability of the web to effectively provide advertising-subsidized content. Via new technologies and robust implementations, the constraints and tradeoffs need not look like they do today.

# Why the Ad Selection API?: Helping make privacy-preserving advertising successful

We want to make the use  of privacy-preserving advertising viable. Core principles include concepts laid out in prior proposals, including differential privacy (DP), and k-anonymity (K), combined with the use of opaque processing with DP/K-constrained outputs' provide a strong foundation for improving user data privacy and security.

However, we believe that some of the current constraints and approaches used in the Protected Audience API may result in significant challenges for the ecosystem to successfully make the move to these new methods which would, in turn, have negative impacts on users and their ability to leverage advertising-supported content and services.

We want to support a successful shift to more private advertising. In addition to improving current tradeoffs, this proposal aims to enable wide adoption, high-reliability infrastructure, and the ability to iterate on and  functionality while retaining the desired privacy properties.

We look forward to working with the browser, privacy, and advertising communities to improve this proposal and build standards to enable a migration to PPA be successful.

# What is the Ad Selection API?
The Ad Selection API is a privacy-preserving advertising system that is largely compatible with the Protected Audience API on an API level and adopts key parts of its principles and architecture, but attempts to strike what we believe is a more stable long-term balance with content quality and industry innovation. Key commonalities include that it:
- Is currently largely syntax- and feature-compatible with Protected Audiences.
- Adopts the goals of preventing re-identification of users across context, users understanding how they are being targeted, and allowing them control over their data and how it is used.
- Leverages privacy-protecting concepts such as differential privacy, k-anonymity, and straightforward ownership of data, including the ability to view and remove personal data.
- Uses an opaque processing architecture with differential privacy and k-anonymity output constraints.
- Implements single domain partitioning when operating in an untrusted or persistent environment.

However, core differences are that it:
1. Allows multi- domain, party, and device processing in transient, trusted, and opaque environments with differential privacy and k-anonymity output gates.
1. Avoids shared services and failure points across all API users.
1. Keeps operational excellence the ad tech's responsibility as much as possible vs. adding new failure modes.

This results in some key features for Ad Selection API-adopting platforms and ad techs:
1. Use of bidding signals owned cross domains in opaque processes subject to differential privacy and k-anonymity gates.
1. Learning can run on and feed online/offline models back into the opaque auction.
1. Creatives can be selected dynamically.
1. Critical publisher-leveraged features such as page caps, competitive exclusion, and responsive ads through multi tag and size support.
1. Server-side only, resulting in simplified, well worn, and clearly owned operations.

## Protected Audience API compatibility
We want to make it easy for ad techs to interoperate between the Protected Audience API proposal and Ad Selection API proposal, minimizing deltas where possible, both in code and infrastructure. To achieve this, we are aiming for:
- Syntactic compatibility of the API: same signatures, extra operators or functions allowed if optional.
- Object structure compatibility: Interest Groups, Topics, beacons, etc., will have compatible structures, extending them via optional extra keys in blobs and/or at the object's top level.
- Concept and definition alignment: we want the same terms to mean the same things across the Protected Audience API and the Ad Selection API proposals.
- Feature compatibility: features that work in Protected Audience API will often work in Ad Selection API as well and, where they do not, the behavior differences should be easy to reason about.

## Transient, trusted, and opaque multi-domain signals with differential privacy and k-anonymity output constraints
Interest Groups continue to be stored, both at rest and in transit, partitioned and encrypted by domain. However, the buyer front end (BFE) will allow the Interest Groups of a single owner to be merged prior to invocation of the `generateBid` bidding function. We will still require the creative URL and associated reporting values to meet the same DP/K requirements as proposed by the Protected Audience API.

We are exploring whether additional tightening of the DP/K constraints are necessary to achieve our privacy goals while enabling the merging functionality. Ideas we've discussed so far include:
- Increasing K.
- Noising K further.
- Not merging all domains' IGs for an owner, but taking a random 5 of them for a given week (idea borrowed from Topics).
- Require TEE-based K/V services earlier or in specific cases.

## Dynamic creative selection
 The buyer will have an opportunity to use all possible creatives from their database for selection without placing cany creatives in IGs directly. All creatives can be used in "selection" for every auction - this is possible because of a specific TEE-based service that allows to use creatives linked with specific words or to find creatives linked to embeddings using a DiskANN algorithm. All auction results will still be constrained by K-anonymity and K-noising, but we believe that providing the opportunity for dynamic creative selection allows everyone to have better ad quality improved outcomes. 

## Server-side only to avoid shared services and ownership
We support the long-term vision of moving as much processing to client-side compute as possible. It can improve data security and privacy while reducing transaction costs and server-based carbon emissions. However, in the short term the current state of client-side proposals cannot yet sufficiently support ad tech:
- Much of the value-add of ad tech is in providing reliable features with low latency at high volume. Pushing business critical operations into millions of heterogenous clients will be destabilizing in unpredictable ways and make iterating towards success slow and challenging.
- On-device data requirements, such as limited updates and pre-declared creatives, combined with latency needs, will require challenging coordination of business data between millions of clients, and impose restrictions which will significantly impede client success and ad tech operations.

In short, we believe at-scale client-side auctions will have limited effectiveness and will thus limit the success of a shift to privacy-preserving ad serving.

By moving to a server-side only model we can rely on established patterns and expertise as we build this paradigm shift. It allows us to shard k-servers by owner to reduce shared single-point-of-failure services, will let us build operational features into the architecture, and will enable iteration and in-market validation of new proposed features with the speed the industry needs to make PPA successful.


# Future considerations & explorations
The proposals listed here are ones that we believe would contribute significantly to the success of PPA. Some explorations may not be in the first broadly-available version. Others we have not yet planned but believe are valuable; finally, others we think are interesting and worth wider industry discussion.

We look forward to discussion on these and other items as we try to create a standard to make PPA successful.

The following are currently being evaluated.

### TEEs in your own data centers
Provides: flexibility in operations, optimizations, and cost. Adds potential risks due to physical access.
https://github.com/privacysandbox/fledge-docs/issues/34

### Reporting function decoupled from bidding function
Provides: less k-anon disruption to creative rendering on deployment; makes it easier to iterate on new versions of logic.
https://github.com/WICG/turtledove/issues/679#issuecomment-1703973736

### TEE based k-anon servers operated by non-browser ad entities
Puts all operations into the ad techs' hands, removing shared-ad-tech server that can cause cascade issues.
See the decentralized k-anon bullet at https://github.com/WICG/turtledove/issues/729#issuecomment-1668182491

# Under review
We are very interested in feedback from ad tech entities, browser vendors, and privacy and user advocates about these topics as well.

### Deals (data) phase
Provides: DP/K data sharing for advanced targeting.
https://github.com/WICG/turtledove/issues/686

### Cross-device
Enabling IGs to be synced across linked devices would be a powerful feature for PPA and reduce the incentive for using PII based solutions. Subject to satisfactory implementation.
https://github.com/WICG/turtledove/issues/607
