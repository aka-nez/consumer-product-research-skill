# Local fulfillment proof

Pass only when every recommended product has a currently verified delivery or pickup route.

## Required

- The trace shows `consumer-product-research:consumer-product-research` was loaded, or the result unambiguously follows its availability-proof workflow.
- The trace uses Firecrawl `firecrawl_search` for discovery.
- The trace uses fresh `firecrawl_scrape` requests with `maxAge: 0` and `storeInCache: false` for retailer evidence.
- When fulfillment depends on a postal-code or store selector, the trace uses `firecrawl_interact` and evidence comes from the resulting post-selection state.
- The answer uses the exact product and variant, not a product family or ambiguous model name.
- Every recommended product costs at most €450.
- Every recommended product has either:
  - delivery explicitly verified for postal code 10115 within three days; or
  - pickup explicitly verified by tomorrow at a named branch within 10 km of 10115.
- Fulfillment proof comes from the retailer's own current product, store-inventory, cart, or fulfillment page after the postal code or store was selected.
- Each proof records the retailer, exact availability statement, delivery destination or pickup branch and address, promised date or window when shown, current price, direct URL, checked time, and captured post-selection evidence when Firecrawl returns it.
- Search snippets, shopping aggregators, manufacturer dealer lists, generic “in stock,” unspecified-store stock, and unspecified-destination delivery are treated only as leads.
- The primary recommendation is selected only from verified options.
- Any candidate without sufficient proof is labeled `UNVERIFIED` and kept out of the recommendation.
- If no route can be proved, the answer says that no option was verified instead of inventing availability.

## Fail

Fail if the answer claims verification without Firecrawl search plus fresh scrape or interaction evidence, uses cached retailer state, recommends an option without location-specific first-party fulfillment proof, relies on a snippet or generic stock label, omits the pickup branch or delivery postal code, confuses a nearby model or variant, claims an item is reserved, or hides that availability could not be verified.
