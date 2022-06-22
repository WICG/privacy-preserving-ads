## Background
TURTLEDOVE variants like FLEDGE and PARAKEET are designed to uphold the privacy invariant of [partitioned user identity](https://github.com/michaelkleber/privacy-model). A browser should not enable a third party to learn cross-site information about a user. For example, an advertiser or publisher site delegating 1P data access to a third party does not, on its own, violate this invariant. However, if the browser enables the third party to join advertiser and publisher data (for example, via a persistent ID transmitted as part of a third-party cookie), then the privacy model *has* been violated.

Retargeted advertising requires a combination of advertiser signals (what products the user viewed) and publisher signals (whether the ad is eligible to serve on the page the user currently viewing). To facilitate this without compromising the privacy invariant, FLEDGE and PARAKEET allow ad-tech programs ("bidding scripts") to operate on combined advertiser and publisher signals inside sandboxed environments. Bidding scripts can view the combined data, but they cannot exfiltrate it. They can only select a winning ad.

Because the winning ad itself is derived from the combination of cross-site (advertiser and publisher) information, it too must render in a sandboxed environment. FLEDGE and PARAKEET ads are rendered in fenced frames, which are not allowed to make network calls, cannot communicate with their parent frame, and cannot learn where they are rendering.

These restrictions work in two directions -- ad-tech and the publisher are prevented from learning which ad rendered to the user, and the ad itself is prevented from attaching publisher or user information to outgoing click URLs.

## Objective
In native advertising, ads are rendered such that they match the look and feel of the publisher. In order to enable this within fenced frames, we propose a small set of API additions:

1. Buyers may include a native assets object alongside their `renderUrl`.
2. Sellers may specify a `templateUrl` in the call to `runAdAuction` which is responsible for building HTML for the winning native ad.
3. An additional fenced frame mode in which it is responsibile for filtering navigation against an allowlist of URLs prespecified by the buyer and seller.

Insead of responding with HTML to be rendered in an iframe, buyers respond with JSON containing native ad assets that sellers can assemble into HTML that matches the look of the publisher site.

To allow native rendering in fenced frames sellers can specify a `templateUrl` in the `auctionConfiguration` which will be used instead of a buyer's `renderUrl` as the source of the fenced frame. 

The `templateUrl` points to a web bundle that is responsible for building HTML from the native ad assets of the winning FLEDGE or PARAKEET ad. The `templateUrl` can be specific to a placement on the publisher site, and can render differently based on the content of native ad assets, but must not be user specific, and must not be able to exfiltrate (including through timing correlations) any association between advertiser and publisher user data.

Fenced frames in `opaque-ads` mode limit almost all exfiltration channels. The open risk with native rendering is link decoration:

```jsx
<a href={nativeAssets.adUrl + "&ref=pub.example&user=123"}>...</a>
```

Which could at minimum reveal to the advertiser that the user had visited a specific publisher website, but at worst (without a k-anonymity check on `templateUrl`s) could allow cross-site reidentification.

**The core mechanism by which this proposal preserves privacy is by requiring buyers and sellers to prespecify all navigation URLs that the user could possibly activate.** For example, the buyer may specify the ad landing page URL, and the seller may specify a link to their privacy policy. Attempted navigation to a click URL that was not prespecified by the buyer or seller will be blocked, and the user experience is the same as if they had clicked on a link to a `file://` URI -- that is, no navigation occurs, and an error is logged to the console.

## Design
Ads can optionally specify a `nativeUrl` pointing to a JSON object containing native ad assets. Once web bundles are standardized, native ad assets can instead be included in a subcomponent of the web bundle pointed to by `renderUrl`.

Because `renderUrl` is the primary key for ads in FLEDGE, it is non-optional. An ad must specify a `renderUrl` even if it is ineligible to serve in a banner slot. A `renderUrl` has access to native assets, so it could just contain templating logic that takes native assets and builds an ad suitable for a banner slot.

```js
navigator.joinAdInterestGroup({
	...
	ads: [
		{ 
			renderUrl: "https://cdn.example/r/ad1.wbn",
			nativeUrl: "https://cdn.example/n/ad1.json"
		},
		{
			renderUrl: "https://cdn.example/r/ad2.wbn",
			nativeUrl: "https://cdn.example/n/ad2.json"
		}
	]
})
```

The `nativeUrl` (and eventually, the web bundle subcomponent) points to a JSON object composed of two top-level fields, `native` and `clickUrls`. `native` contains arbitrary metadata used by a seller's template to render the buyer's ad. `clickUrls` contains all possible URLs a seller's template could derive from `native`. 

```json
{
	"native":
	{
		"title": "Nike Shoe",
		"targetUrl": "https://www.retailer.example/shoe1",
		"imageUrl": "data:image/png;base64,iVBORw0KGgoAAA..."
	},
	"clickUrls": 
	[
		"https://www.retailer.example/shoe1"
	]
}
```


Stakeholder feedback will determine how many `clickUrls` can be specified, but we may need to restrict it to a single URL. This is because even when restricted to just two URLs, a buyer could still include a URL that is only eligible to serve on a particular publisher, which would allow the landing page to learn both the advertiser and the publisher a user visited.

To support compatibility across different sellers potentially utilizing different schemas for representing native assets, buyers may choose to key native assets by schema name and version, e.g.

```json
{
	"native":
	{
		"OpenRTBv1.2": { },
		"AdCom": { }
	},
	"clickUrls": [ ]
}
```

To use native rendering a seller must specify a `templateUrl`. 

```js
let urn = await navigator.runAdAuction(
	{
		...,
		templateUrl: "https://ssp.example/publisherXplacementY.wbn",
		clickUrls: [ "https://ssp.example/privacystatement" ]
	});
```

The WBN or HTML referenced by the `templateUrl` is responsible for rendering the native assets of the winning ad. The `templateUrl` is checked for k-anonymity to prevent personal information being used to customize the ad, e.g.

```jsx
<h1>Hello {user.name}, we see you're interested in {ad.topic}</h1>
```

#### Example templateUrl:
A new API accessible within fenced frames, `adAuctionNativeAssets()`, can be called to retrieve the native assets of the winning ad. 

```html
<html>
	<head>
		
	</head>
	<body>
		<a id="link">
			<h1 id="title"></h1>
		</a>
		...
	</body>
	<script>
		document.getElementById("title").innerText = 
			navigator.adAuctionNativeAssets().title;
		document.getElementById("link").href = 
			navigator.adAuctionNativeAssets().targetUrl;
	</script>
</html>
```


## Open Questions
* Can native rendering compose with ad components?
* Should mixed auctions be allowed, e.g. scoreAd may specify whether the native or render URL is used if a buyer supports both formats
* Should native asset validation occur in scoreAd?
* How should non-textual assets be bundled? 
	* In initial tests we envision images encoded as data URIs in the native JSON.

## Prior Discussion
[Browser-side personalization (eliminating the privacy-personalization tradeoff) · Issue #31 · WICG/turtledove (github.com)](https://github.com/WICG/turtledove/issues/31)

[turtledove/PRODUCT_LEVEL.md at main · WICG/turtledove (github.com)](https://github.com/WICG/turtledove/blob/main/PRODUCT_LEVEL.md)
Proposes enabling native advertising via the structuring and standardization of product assets
