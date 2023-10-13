# MPC and measurement ad-hoc call
Nov. 8, 2021

GitHub issue: [https://github.com/WICG/privacy-preserving-ads/issues/39](https://github.com/WICG/privacy-preserving-ads/issues/39)

## Agenda
Host: Erik Anderson

Scribe volunteer: Mariana Raykova

* Intros
* _High-level_ overview of current activity in this space
    * [Attribution Reporting API with Aggregate Reports](https://github.com/WICG/conversion-measurement-api/blob/main/AGGREGATE.md), proposing a DPF-based approach with two helper services.
    * [Secure Multi-Party Aggregation using oblivious bucketization](https://github.com/WICG/privacy-preserving-ads/blob/main/Bucketization.md), an alternative crypto approach which aims to provide same protections as DPF.
    * [Masked Learning, Aggregation and Reporting worKflow (Masked LARK)](https://github.com/WICG/privacy-preserving-ads/blob/main/MaskedLARK.md), which aims to better solve model training but reveals keys to helpers.
    * Privacy Preserving Measurement Protocol
        * Privacy Respecting Incorporation of Values (priv) IETF Birds of a Feather session happening on Wednesday, Nov. 10 ([https://datatracker.ietf.org/meeting/112/agenda/](https://datatracker.ietf.org/meeting/112/agenda/), [https://www.ietf.org/live/ietf112-priv/](https://www.ietf.org/live/ietf112-priv/))
        * Protocol document: https://datatracker.ietf.org/doc/draft-gpew-priv-ppm/
        * Crypto document: https://datatracker.ietf.org/doc/draft-patton-cfrg-vdaf/
    * Anything else?
* Roundtable:
    * What properties of helper services are an absolute requirement?
    * What use cases are critical to solve and what are explicitly out of scope? In particular, where does model training fit?
    * Where are the best locations to collaborate? A new IETF WG? W3C’s PATCG? Any other forums?
* Any other business

##Attendees:
1. Erik Anderson (Microsoft Edge)
2. Peter Saint-Andre (Mozilla)
3. Tim Geoghegan (ISRG/Let’s Encrypt)
4. Michael Kleber (Google Chrome)
5. Charlie Harrison (Google Chrome)
6. Joel Pfeiffer (MSFT)
7. Mariana Raykova (Google)
8. Denis Charles (Microsoft)
9. Nishanth Chandran (Microsoft)
10. Martin Pal (Google Chrome)
11. Betul Durak (Microsoft)
12. Adria Gascon (Google)
13. Andrew Pascoe (NextRoll)
14. Kelda Anderson (Microsoft Edge)
15. Phillipp Schoppmann (Google)
16. Harneet Sidhana (Microsoft Edge)
17. Christopher Patton (Cloudflare)
18. Jonasz Pamuła (RTB House)
19. Przemyslaw Iwanczak (RTB House)
20. Kim Laine (Microsoft)
21. Divya Gupta (Microsoft)
22. John Wilander (Apple WebKit)
23. Luke Winstrom (Apple)
24. Nicolas Arciniega (Microsoft Edge)
25. Karn Seth (Google)
26. Brandon Maslen (Microsoft Edge)

## Notes
* No expectation for decisions made here but just educating everyone
* Intros and overview of existing proposals (see above)
* Any other proposals of interest? (no)
* Some question about DPF/Prio proposals:
    * How full is the codebase about DPFs? What benchmarks should we be aiming for? What about DP? Which test vectors should we use? Etc.
        * Chris Patton: draft of a proposal for distributed MPC classes, we do have an implementation but not yet test vectors - goal to have standardization at the IRTF, there's a meeting on Thursday at the IETF meeting
        * Examples for histograms and aggregation buckets
        * Pasin: What data types are you considering for Prio/PPM? Chris: For histograms, specify the buckets and aggregators need to agree on the boundaries (similar to something like Prometheus)
* Mariana: I think we need to look at the higher level topics :-)
* Erik: also questions about where work is happening
    * PPM/Prio at IETF/IRTF
    * PATCG starting up
    * WICG discussion
    * We've talked about threat models before, too - where should that go?
* Threat models - where should we discuss it and also have an interoperability across solutions
    * Charlie: how to split the layers of abstractions - the IETF workstream does aim to have a threat model. Different applications might need different models and we want to have the right level of abstraction
    * Peter - IETF workstream working on crypto primitives (IRTF CFRG) and the BoF will be looking at measurement as an application (IETF PRIV BoF), W3C efforts should build on top of what crypto is developed at IETF
    * Erik: unclear whether there are other parallel efforts going on, would the current BoF charter be sufficient 
    * PATCG chartered but still forming - should talk about use cases rather than architecture and solutions?
    * Call for action - think about we need more than the scope of the current BoF
        * Peter: If there are other MPC solutions probably should go into the BoF, depends also on how much energy there is for developing such solutions
        * Tim: Chris and I and others have defined a construction for VDAF. We're trying to coordinate execution of VDAFs - currently Prio and Heavy Hitters; eventually could have more of these that could plug into the PPM/PRIV protocol. Do other MPC systems fit in the PPM/VDAF framework?
        * Charlie: My biggest concern with VDAF is that we might be overly constrained by Prio and HH. The best input would be use cases that radically challenge this overall structure. This will come out of things like [MaskedLARk](https://github.com/microsoft/MaskedLARk) as a VDAF. As a general framework I think it's decent and we should make an effort to integrate that into the PPM/PRIV work. We've been focused on aggregation and we need to define what that really means.
        * Peter: The point of BoF - do we want to create a working group, good to hear from other people with different use cases
* Erik: As part of PATCG - how can we be more inclusive to other parts of the system compared to W3C. How have people been coordinating on the crypto side?
    * Chris: Git repo for PPM to get started, ISRG organizing weekly calls, ad-hoc discussion so far, that discussion will be migrating to CFRG and PRIV WG once it's formed.
    * ?: There are some approaches to fit model training with DPF
    * Charlie: not a lot of new crypto work beyond Prio and HH papers, now is a good time to bring in more MPC models and researchers
    * Mariana: there are many proposals and they are at different levels of abstraction, still with lots of open questions related to differential privacy etc. - other proposals are more worked out. We should take this into account when drawing conclusions. Also I wonder if we should specify the goal of this group. One thing I think could be useful is that there are a lot of proposals and protocols - coming up with a summary of these things and their properties (plus implementation insights) could help us compare across these things regarding guarantees, threat models, DP leakage, etc.
    * Betül: most of what you're talking about has been worked out to some degree, we had a document / report (where??) with a table etc. These technologies will all have many of the same benchmarks etc.
        * [DPF paper](https://arxiv.org/abs/2012.14884)
    * Phillipp: I can definitely provide some benchmarks - but it's early and we don't really know how the data will look like in reality
    * Betül’s [writeup](https://github.com/WICG/privacy-preserving-ads/blob/main/Bucketization.md), a PDF writeup with more details is coming "very soon"
* Uses beyond ads? Definitely want to get that input for the protocol work
* What about the crypto work specifically?
    * https://irtf.org/cfrg is the CFRG at IRTF and hopefully the VDAF document will be adopted as a CFRG work item
* Peter: Clear path for PPA, not so sure for the other directions
* Mariana: ML training is a challenging topic and that's probably beyond the PPA focus
* Charlie: eventually we'll want to bubble these conversations over to CFRG / IETF so they're clear on the use cases - but I think in order to be good contributors there we'll want to complete due diligence so that we can engage productively
* Erik: hopefully we can figure out how to winnow down the set of groups at W3C where we have these discussions and get involve PATCG once it is up and running
