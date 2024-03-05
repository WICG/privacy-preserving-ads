# Ad Selection API Design

This document describes the planned design, model, and infrastructure of the Ad Selection API. Ad Selection API is a proposal for a private advertising auction framework that is designed to be largely compatible with the Protected Audience API (including its core privacy principles) while improving the ability for the web ecosystem to continue to monetize effectively and reliably.

# Auction design elements
## Framework

Ad Selection API provides a private advertising framework to run auctions that ad techs can plug in to. The framework enforces constraints that allow for consumer assurance on:
- Re-identification
- Passive accumulation and usage of consumer data across sites
- Ability to delete data.

The pluggability allows businesses to add functionality using callbacks at key auction points such as bidding, ranking, reporting, and data retrieval.

Consumers benefit from the ability to hide in a crowd, understand how they are being targeted, and remove themselves from different forms of targeting. These are expressed through guarantees of differential privacy, k-anonymity, and data visibility, which can be enforced by the framework.

Ad techs plug into the framework using:
- Objects with attributes used in framework processes.
- Functions with defined signatures that can contribute to the auction.
- Constrained calls to servers to allow limited data ingress and egress.

Next, we'll dig into the primary design elements of the Ad Selection API Auction: interest groups and the private auction.

## Interest groups

Impressions are targeted, bid on, and won by Interest Groups (IGs). An IG is “joined” locally on the user's client by ad-tech code using APIs exposed by the client. Once joined, it may participate in any private auction initiated on that device. It has a time-to-live (TTL) of up to 30 days, which can be extended on further interactions.

The IG combines elements of current ad tech functionality related to bidding and targeting:
- Targeting signals.
- Bidding and valuation logic.
- Real-time key lookups.

The private auction uses the IGs joined by the browser during the bidding process, allowing the owning DSP to submit a bid for a creative, and to report back to their server.

While the IG has a defined top-level structure that interacts with the private auction, there are free-form properties that can be defined and updated by the ad tech as they wish to support their own business models.

The consumer is able to see the IGs they have joined and remove themselves if they don't wish to be targeted in that way anymore.

You can see more detail on IG structure and usage in Step 0 of [Life of an Ad Request](life of an ad request.md), or in our [API Spec](api details.md).


## Private auction
### Auction

Let's start with the auction part of the private auction (PA).

Similar to how a web application framework responds to API requests by invoking callbacks registered by the business, the private auction does the same for auction requests. The PA is initiated by the publisher based on settings it defines and any previously registered IGs it chooses to include. During the auction lifecycle, the framework invokes callbacks for bidding, ranking, and reporting, as well as making parameterized calls for limited injection of real time data.

Once initiated the PA:
- Invokes any included IG bidding functions to allow targeting, valuation, and if desired a bid for a creative.
- Routes bids to the publishers ranking function to determine a winner for each auction.
- Can render the winning results and invoke reporting functions.

The PA itself results in 0 or 1 creatives per auction that are available to render. Tools are provided for the publisher to make a choice between the PA result and the result of any non-Ad Selection API-based auction run through existing channels.

You can see much greater detail on the Auction Flow in [life of an ad request](Life+of+an+Ad+request.md).

While the interest groups and the private auction define structure and process, they are designed to allow ad techs to map their own domain models, objects, and flows onto it. The intention is to allow buying and selling to happen based on existing signals.

### Privacy in the auction

Let's dig in on the private part of private auction.

We are aligned with the Protected Audience API proposal's goal of preventing re-identification across contexts (see here and here for discussion). The very high-level design is to allow sensitive data to be processed in transient and opaque processes, but for the observable output of those processes to be tightly constrained.

The constraints on those processes include:
- Differential privacy
- K-anonymity
- Entropy

Many of these constraints are enforced via the use of Trusted Execution Environments (also known as “confidential computing”) which can provide guarantees around what code is running and protects against outside observations about what happens within the protected environment.

Example applications of these constraints include:
- Creative URLs may not be unique to any less than 50 browsers, ensuring that microtargeting cannot occur based on creative.
- Certain targeting parameters are not reported based on the same threshold.
- Constrained precision on bid values to prevent clever usage of bits for identification.
- Noise in attribution reporting.

Using a framework-based approach, in which attestable well-known code runs the auction and exposes sandboxed hooks for businesses to plug into, allows Ad Selection API (and Protected Audience) to design in and enforce privacy guarantees in a way that cannot be done otherwise.


## Infrastructure design elements

When evaluating options for physical infrastructure of Ad Selection API, we strongly considered:
1. Privacy constraints: all the good algorithms in the world aren't helpful if your processes are easily compromised.
1. Ad tech scale and volume: monetizing content through digital advertising relies on low latency at very high volume.
1. Ability to maintain and operate: Ad Selection API, or any other PPA system for that matter, will not succeed if it cannot be effectively operated.

We believe on-device auctions provide a lot of value in enabling effective enforcement of privacy constraints and have many attractive characteristics; however, we see them as not generally ready for (2) and presenting novel challenges for (3). We see (2) and (3) as being essential to the success of PPA, as the alternative is a system incented to operate on PII that is shared across contexts.

This has led us to a sever-side only solution, operated by individual ad techs, that can leverage well-worn patterns for scaling, deployment, and management.

As Protected Audience API proposes in their [Bidding and Auction services](https://github.com/privacysandbox/fledge-docs/blob/main/bidding_auction_services_api.md) extension, we intend to leverage Trusted Execution Environments (TEEs) running attested code in a constrained runtime.

### Confidential computing
Confidential computing is an emerging field focused on protecting data while it is being processed. Traditionally, data security has been more concentrated on data at rest (stored data) and data in transit (data being transferred over a network). However, as data must be decrypted for processing, it becomes vulnerable to various threats, including both internal and external attacks that could expose cross-contextual information to an adversary. Confidential computing aims to address this gap by providing ways to encrypt data in memory and elsewhere during execution.

### Trusted Execution Environments (TEEs)
Confidential computing utilizes hardware support in modern CPUs to create Trusted Execution Environments (TEEs) where code and data is isolated from unauthorized users, including those with administrative privileges or physical access to the hardware.  The TEE provides a higher level of security than a regular operating environment by ensuring that the code and data loaded inside the TEE are isolated and protected using remote attestation to ensure configuration before sharing data. This enables confidential computing, where you can run applications in a secure and isolated environment, even if the broader system is compromised.

Learn more about [Azure Confidential Computing](https://azure.microsoft.com/en-us/solutions/confidential-compute/#overview)

### Isolated Worklets
_No network, disk access, timers, or logging._

All the logic of the on-device auctions will execute inside a collection of dedicated **_worklets_**.  Each worklet is associated with a single domain, and runs code written by either a buyer or a seller.  The code in the worklets cannot access or communicate with the publisher page or the network.  The auction framework is responsible for instantiating those worklets, loading the relevant buyer or seller logic from the provided URLs, fetching real-time data from a trusted server, calling the appropriate functions with specified input, and passing on the output.  We will publish a separate explainer on dedicated worklets.

Worklets are run inside Roma which you can see documentation for [here](https://github.com/privacysandbox/fledge-docs/blob/main/bidding_auction_services_system_design.md#roma)
