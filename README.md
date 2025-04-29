This is the repository for various privacy-preserving ads proposals.

# Ad Selection API Proposal
## Overview
The documents in this repository are meant to help describe the Ad Selection API, a privacy-preserving ads (PPA) proposal that is substantially similar to other ad serving proposals from a structure, flow, and syntax perspective, but with some core differences related to overall model and infrastructure that we believe provide critical capabilities that will enable the open web ecosystem to effectively move to privacy-preserving ads APIs.

We plan to hold regular meetings under the auspices of the WICG to go through the details of this proposal and quickly respond to feedback. Please comment on the timing question in [Issue #50](https://github.com/WICG/privacy-preserving-ads/issues/50) if you want to participate in these meetings to influence the direction of the proposal.

If you are ready to dive in, we recommend you start with the following content:
- The [**Ad Selection API overview**](Ad%20Selection%20Overview.md), which describes the proposal at a high-level including descriptions of privacy model, infrastructure, and features.
- The [**Auction & infrastructure design**](Auction%20&%20Infrastructure%20Design.md), which contains diagrams of the auction and ad serving flows and how they are similar and different to other proposals in this space.

Since this API leverages similar concepts from other proposals, some of the concepts referenced are already well-described in those proposals' GitHub repositories. We aim to minimize duplicative explanations and definitions in favor of focusing on documenting key additions and differences.

## Documents in this repository:
1. Proposal overview
     1. [**Ad Selection API overview**](Ad%20Selection%20Overview.md): an overview of the Ad Selection API, including the rationale for a new proposal
     1. [**API differences**](API%20Differences.md): a high-level overview of differences between Ad Selection API and other industry proposals.
     1. [**Auction Reporting**](Auction%20Reporting.md) 
     1. [**Attribution Reporting**](Attribution%20Reporting.md)
     1. [**Selection hook implementation**](GetNearestNeighbors%20hook%20implementation.md)

1. Data flows & examples
     1. [**Auction & infrastructure design**](Auction%20&%20Infrastructure%20Design.md)
     1. [**Life of an ad request**](Life%20of%20an%20Ad%20Request.md)
1. [**API specification**](API%20Details.md)

## Background reading: the [Protected Audience API](https://github.com/WICG/turtledove/blob/main/FLEDGE.md)
Since this proposal leverages many of the concepts and terms used in the the Protected Audience API proposal, we recommend you review the following resources as a part of reviewing this proposal:
- Interest groups and the on-device auction:  https://github.com/WICG/turtledove/blob/main/FLEDGE.md#design-elements
- Server-side auction goals and motivations:  https://github.com/privacysandbox/fledge-docs/blob/main/bidding_auction_services_api.md#bidding-and-auction-services and https://github.com/privacysandbox/fledge-docs/blob/main/trusted_services_overview.md#overview-of-fledge-services
- Key terms from https://github.com/privacysandbox/fledge-docs/blob/main/trusted_services_overview.md#key-terms-and-concepts,
- TEE definitions from https://github.com/privacysandbox/fledge-docs/blob/main/trusted_services_overview.md#trusted-execution-environment
- Security goals from https://github.com/privacysandbox/fledge-docs/blob/main/trusted_services_overview.md#trusted-execution-environment
- Trust model from https://github.com/privacysandbox/fledge-docs/blob/main/trusted_services_overview.md#trust-model


# Archived Proposals
This repo has hosted a variety of proposals intended to help with the effort to enable privacy-preserving advertising on the web. While these proposals are not actively being worked on, we offer historical links here for educational purposes.
* [PARAKEET: Private and Anonymized Requests for Ads that Keep Efficacy and Enhance Transparency](archive\Parakeet.md)
  * [PARAKEET polyfill](https://github.com/microsoft/PARAKEET/tree/main/Polyfill)
* [PARAKEET with Noisy Ranking](archive\NoisyRanking.md)
* [MaCAW: Multi-party Computation of Ads on the Web](archive\MACAW.md)
* [Masked LARK: Masked Learning, Aggregation and Reporting worKflow](archive\MaskedLARK.md)
