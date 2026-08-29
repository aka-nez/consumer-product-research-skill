# Attributed review evidence

Reviews answer whether a product is good. They never answer whether the user can get it. Pass only when both stay separate and every bullet is sourced.

## Required

- The trace shows `consumer-product-research:consumer-product-research` was loaded, or the result unambiguously follows its workflow.
- Fulfillment is proved first, and review work happens only on candidates already labeled `VERIFIED DELIVERY` or `VERIFIED PICKUP`.
- Every pro and con carries exactly one source: a link, an author or channel, and a publication date.
- Video transcripts are read with `firecrawl_scrape` of `https://youtubetotranscript.com/transcript?youtube_url=<watch URL>`, not by scraping the watch page and not with an `actions` array.
- A video whose transcript could not be retrieved appears as a cited lead with channel, title, date, and link, and produces no pros or cons.
- Each source records the variant it tested. A review of a different model year, size, or regional variant is excluded, or its bullet is one that does not depend on size and says so.
- Owner reviews appear as an aggregate with the number of reports behind them, never as a single anonymous opinion presented as a finding.
- Sponsorship, affiliate, or supplied-unit disclosures stated by a source are recorded on that source.
- The recommendation is still gated on fulfillment: no product without a verified route is recommended, whatever its reviews say.
- When reviews change the ranking of verified candidates, the answer says which finding did it.
- At most three candidates are reviewed, at most three sources each.
- The saved report carries a `reviews` JSON island alongside `checks`, and earlier records survive verbatim.

## Fail

Fail if any bullet lacks a source link, if pros or cons are derived from a video without a transcript, if a source's claims are merged into "reviewers generally say", if review strength promotes a product whose route is `UNVERIFIED`, if a differently sized or older model's review is passed off as the candidate's, if reviews run before fulfillment is settled, if an exhausted allowance during the review stage discards the verified fulfillment result, or if the answer scrapes the YouTube watch page or passes `actions` to `firecrawl_scrape`.
