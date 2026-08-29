# Review Evidence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add attributed review pros and cons to the report, sourced from written reviews and, where a transcript is obtainable, video reviews, without weakening the fulfillment proof standard.

**Architecture:** No new component. The existing Firecrawl connection gains a second, later stage that runs only on already-verified candidates and writes to a second JSON island in the same self-contained HTML report. No transcript service, API key, dependency, or file is added.

**Tech Stack:** `skills/consumer-product-research/SKILL.md`, the report's inline JSON islands, Claude Code native eval cases.

**Spec:** `docs/superpowers/specs/review-evidence.md`

## Global Constraints

- Keep one behavior source at `skills/consumer-product-research/SKILL.md`.
- Add no MCP server, credential, dependency, script, or runtime; `firecrawl_search` and `firecrawl_scrape` are the only fetchers.
- Review evidence never gates recommendability and never substitutes for a fulfillment route.
- Every bullet carries exactly one source; unattributed or merged claims are prohibited.
- The review stage runs after fulfillment proof, never before or interleaved.
- Bump `.claude-plugin/plugin.json` once, at the end, when behavior is final.
- Do not run project-wide reformatting; edit only the files each task names.

---

## File Structure

| File | Responsibility |
|---|---|
| `skills/consumer-product-research/SKILL.md` | Review stage: sourcing, variant discipline, extraction, budget, report islands. |
| `evals/review-evidence-attribution/prompt.md` | Stimulus for a request whose answer needs review sourcing. |
| `evals/review-evidence-attribution/graders/criteria.md` | Attribution, no-fabrication, and gating criteria. |
| `docs/superpowers/specs/review-evidence.md` | Authoritative design. |
| `.claude-plugin/plugin.json` | Version bump on release. |

---

### Task 1: Resolve the transcript assumption with a real probe

The only unproven part of the design. Everything downstream branches on the result, so it runs first and costs a handful of credits.

**Files:** none; this task produces a finding recorded in the spec.

Proven on 2026-08-29, so the probe is no longer open-ended. POST `youtubei/v1/player` with the visionOS client context, then GET the returned track's `baseUrl` with `&fmt=vtt`, yields real cues: verified as two plain HTTP calls and again as in-page `fetch` from a `youtube.com` document, 4017 bytes both times. The Firecrawl HTTP API accepts an `executeJavascript` action and returns `javascriptReturns`, so one scrape call can run that pair.

- [ ] **Step 1: Decide whether to ship the recipe at all.** It spoofs a client against an undocumented endpoint, which is contrary to YouTube's terms, and the official Data API cannot substitute because `captions.download` requires the video owner's authorization. Maintainer's call, recorded in the spec before any code. Declining is a supported outcome: written reviews carry the block.

- [ ] **Step 2: Only if shipping.** Confirm the Firecrawl MCP tool exposes what the HTTP API does: one `firecrawl_scrape` on `https://www.youtube.com/robots.txt` with an `executeJavascript` action, checking that the response carries `javascriptReturns`.

- [ ] **Step 3: Run it on three real review videos** in different channels, including one with only auto-generated captions, and record the per-call credit cost and whether cues come back for each.

- [ ] **Step 4: Record the outcome** in `docs/superpowers/specs/review-evidence.md` with the date, the exact call, and the cost.

**Verification:** the spec records the maintainer's decision and, if shipping, an observed transcript from a real review video with its credit cost.

**Branch:** declined or MCP does not expose the action → Task 2 implements only the cited-lead path for video. Otherwise Task 2 includes the call shape. Task 3 onward is unchanged either way.

---

### Task 2: Add the review stage to the skill

**Files:**
- Modify: `skills/consumer-product-research/SKILL.md`

**Interfaces:**
- Consumes: the verified candidate set produced by the existing fulfillment stage.
- Produces: review records for the `#reviews` island; ordering input for the recommendation.

- [ ] **Step 1: Add a review section after the fulfillment sections and before the report section**, so the document order matches the run order.

State: the stage runs only on candidates already labeled `VERIFIED DELIVERY` or `VERIFIED PICKUP`; at most three candidates; at most three sources each; stop early on agreement.

- [ ] **Step 2: Write the sourcing rules.** Discover with `firecrawl_search`, prefer professional reviews with measurements, then video reviews, then owner reviews as an aggregate with a count. Read each source with `firecrawl_scrape`.

- [ ] **Step 3: Write the variant rule.** A different model year, size, or regional variant is not the candidate. Record the tested variant on every record; allow a cross-size bullet only when the claim is size-independent and say so.

- [ ] **Step 4: Write the video rule** using Task 1's finding. Transcript text present, derive bullets from it; absent, record the video as a cited lead with channel, title, date, and link, and derive nothing. Never summarize from a title, description, or search snippet.

- [ ] **Step 5: Write the extraction rule.** Short bullets, concrete and checkable, each traceable to one source; record any sponsorship, affiliate, or supplied-unit disclosure the source states.

- [ ] **Step 6: Extend the untrusted-content rule** to transcripts, review pages, and forum posts.

- [ ] **Step 7: State the interaction with recommendation.** Reviews may reorder or eliminate verified candidates and may never promote an unverified one; the reply's one-line fit sentence may cite a review finding.

- [ ] **Step 8: State degradation.** If the allowance is exhausted during this stage, return the fulfillment result and name the unreviewed candidates.

**Verification:** feed the skill a prompt with a verified candidate and stubbed tool results in which one video returns no transcript. The response must attribute every bullet, must not invent bullets for that video, and must not promote an unverified product.

---

### Task 3: Extend the report

**Files:**
- Modify: `skills/consumer-product-research/SKILL.md`

- [ ] **Step 1: Document the `#reviews` island** with the field set from the spec, alongside the existing `#checks` island.

- [ ] **Step 2: Specify rendering:** pros and cons under each recommendation, every source a link with author, kind, publication date, and tested variant; `transcript: false` rendered as "cited, not summarized"; owner aggregates showing their count.

- [ ] **Step 3: Specify append-only behavior and staleness:** records are never rewritten or dropped; a refresh re-verifies fulfillment, leaves review records in place, and marks records older than six months stale rather than refetching. Refetch only on request.

**Verification:** run the skill end to end on a real request and open the saved HTML. Both islands parse, every rendered bullet has a link, and a second run appends without disturbing the first run's records.

---

### Task 4: Add the eval case

**Files:**
- Create: `evals/review-evidence-attribution/prompt.md`
- Create: `evals/review-evidence-attribution/graders/criteria.md`

- [ ] **Step 1: Write the prompt** as a normal shopping request in a named city whose answer needs review input to choose between close candidates.

- [ ] **Step 2: Write the criteria.** Pass requires: every pro and con carries one source link and date; no bullets derived from a video without a transcript; no review evidence attached to a product lacking a verified route; no recommendation of an unverified product on review strength; tested variant recorded where it differs from the candidate. Fail on unattributed bullets, a summarized-but-unreadable video, review-only recommendations, or silently reviewing more than the budget allows.

- [ ] **Step 3: Add the case to the README eval list.**

**Verification:** the criteria fail a deliberately wrong run, checked by drafting one unattributed-bullet answer and confirming the criteria reject it.

---

### Task 5: Release

**Files:**
- Modify: `.claude-plugin/plugin.json`, `README.md`, `docs/superpowers/specs/minimal-claude-cowork-harness.md`

- [ ] **Step 1: Add the review block to the README** feature list and to the harness spec's skill contract.
- [ ] **Step 2: Bump the plugin version** so marketplace caches invalidate.
- [ ] **Step 3: Validate** with `claude plugin validate . --strict`.

**Verification:** validation passes; the published `plugin.json` shows the new version.

---

## Deferred

- Sentiment scoring, weighting, or a numeric review score: a ranked bullet list with links is what was asked for, and a score hides the sourcing the user wants to check.
- A transcript service, self-hosted Invidious, or API key: revisit only if Task 1 shows Firecrawl cannot reach transcripts and users ask for video coverage anyway.
- Caching review text across runs: reviews are re-read rarely and the island already carries the extracted result.
- Non-English review sources beyond what `firecrawl_search` returns for the user's locale: add when a run demonstrably has no usable local coverage.
