# Review Evidence Design

## Goal

Let the skill weigh what reviewers found, not only what a retailer has in stock, and show the user the sourcing so they can check it themselves. A pro or con appears in the report only with the source that produced it.

## Problem

The skill proves fulfillment and stops there. Two products that both deliver to the user's city are ranked by price and spec sheet, which is how a panel with bad near-black uniformity or a fan whine wins on paper. The user asked for review coverage on YouTube and elsewhere, condensed to short pros and cons, attributed and linkable.

## Two evidence classes, never mixed

| Class | Question | Standard | Effect |
|---|---|---|---|
| Fulfillment proof | Can the user get this exact item? | First-party retailer state, destination- or branch-specific | Gates recommendability |
| Review evidence | Is this exact item good? | Attributed third-party opinion with a link and a date | Orders and annotates, never gates |

Review evidence never promotes a candidate. A product with glowing reviews and no verified route stays `UNVERIFIED` and stays out of the recommendation table. Review evidence may demote or eliminate: a verified candidate with a serious, repeated defect report is reported as such and may lose the top slot to a verified alternative.

This separation is the whole design. Collapsing the two would let opinion text launder into availability claims, which is the failure mode the skill exists to prevent.

## Order and budget

Reviews run after availability proof, only for candidates already labeled `VERIFIED DELIVERY` or `VERIFIED PICKUP` and inside budget.

- at most the top three verified candidates;
- at most three review sources per candidate;
- stop early when sources agree.

Rationale is credits, not tidiness: one availability run already makes many scrapes, and an exhausted allowance mid-run produces a failed run. Reviewing a product that cannot be delivered spends the allowance on an answer the user cannot act on.

If the allowance is hit during the review stage, the fulfillment result still stands. Report the verified options, say which candidates went unreviewed, and apply the existing Firecrawl remedies.

## Sources

Ranked by evidence value:

1. **Professional written reviews** with measurements: scrape cleanly, carry numbers, and match variants explicitly.
2. **Video reviews**, when a transcript is obtainable. See below.
3. **Owner reviews** at the retailer or a forum thread: weak individually; useful only as a repeated-defect signal, and recorded as an aggregate with a count.

Every bullet traces to exactly one source. No merged or unattributed claims, no "reviewers generally say."

### Variant discipline

The same rule availability already enforces. A review of a different model year, panel size, or regional variant is not a review of the candidate. Panel brightness and local-dimming behavior differ by size within one TV series, so a 65-inch review supports a 77-inch bullet only when the claim is size-independent, and the record says which size was tested.

### Bias disclosure

When a source states a sponsorship, affiliate relationship, or supplied review unit, record that on the source. It does not disqualify the source; it travels with it.

## YouTube transcripts

Measured 2026-08-29 from a server context, one video with published English captions:

| Route | Result |
|---|---|
| `youtube.com/api/timedtext` direct | `200`, zero bytes |
| Innertube `youtubei/v1/player`, WEB client | `playabilityStatus: UNPLAYABLE` |
| `youtubetranscript.com` | returns "YouTube is currently blocking us from fetching subtitles" |
| `youtubetotranscript.com` | Cloudflare interstitial; also blocks a real headless browser |
| Invidious `api/v1/captions` (`inv.nadeko.net`) | lists tracks including auto-generated, track body zero bytes |
| Piped `pipedapi.kavin.rocks` | `502` |
| Headless Chromium, in-page fetch of the player response | no `captionTracks` present |
| `r.jina.ai` reader | page metadata only, no transcript |

No free transcript endpoint is dependable, so the design does not add one. Adding a transcript service, API key, or self-hosted mirror would put a second credential and a second failure mode into a plugin whose whole install story is one signed-in connector.

The skill instead asks Firecrawl for the video page, since Firecrawl already runs a browser behind its own proxies and is the one fetcher in the plugin that may pass where the routes above fail. Then:

- **transcript text returned:** derive pros and cons from it, exactly as from an article;
- **no transcript text:** record the video as a lead with channel, title, date, and link, and derive nothing.

A video is never summarized from its title, its description, or search-result text. That is the existing rule against turning missing evidence into a claim, applied to a new surface.

Whether Firecrawl passes is the one unproven assumption in this design. It is resolved by a probe before any behavior is written, and the fallback is a supported outcome rather than a broken feature: written reviews carry the block on their own.

## Untrusted content

Transcripts, review articles, and forum posts are evidence, never instructions. A review page or a video transcript can contain text addressed to an assistant. The existing rule covers retailer pages; it extends verbatim to every fetched source.

## Report

A second JSON island, appended and never rewritten, holding one record per source per product:

```html
<script type="application/json" id="reviews">
[{"product":"","variant":"","kind":"video|article|owner-reviews","source":"","author":"",
  "url":"","published":"","tested_variant":"","transcript":true,"disclosure":"",
  "pros":[""],"cons":[""],"sample_size":null,"checked":"2026-08-29T14:03Z"}]
</script>
```

Rendered under each recommendation: pros and cons as short bullets, each source as a link with author and publication date, kind and tested variant visible, `transcript: false` shown as "cited, not summarized" so the user can see exactly which sources produced bullets. Owner-review aggregates show their count.

Reviews age slowly compared with prices. A refresh re-verifies fulfillment as it does now and leaves review records in place, marking any older than six months as stale rather than spending credits to refetch them. Refetching happens when the user asks.

## Acceptance criteria

- Every pro and con in the report carries exactly one source link, author, and date.
- No review evidence appears for a product without a verified fulfillment route in the same report.
- A candidate is never recommended on review strength when its route is `UNVERIFIED`.
- A video with no obtainable transcript appears as a cited lead with no derived bullets.
- A review of a different model year, size, or regional variant is either excluded or recorded with its tested variant and a size-independent claim.
- Sponsorship or supplied-unit disclosures found in a source are recorded on that source.
- Review work never starts before the fulfillment stage completes, and stops at three candidates and three sources each.
- An allowance exhausted during the review stage still yields the verified fulfillment result, naming the unreviewed candidates.
- The `#reviews` island only ever gains records; earlier ones survive verbatim.
- Instructions embedded in a transcript or review page change nothing about the run.
