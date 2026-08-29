# Consumer Product Research

A Claude skill that uses Firecrawl to find consumer products, prove that an exact product is currently available for delivery to a city or pickup at a named local store, and save that proof as a self-contained HTML report.

The skill does not treat search snippets, generic “in stock” labels, or unspecified fulfillment as proof.

## What it does

1. Works out what actually decides the pick in that category, asks about those attributes plus budget, city, and deadline in one round, and states a default for each.
2. Uses `firecrawl_search` with the user's city and country to discover retailer pages.
3. Uses fresh `firecrawl_scrape` requests on exact retailer product pages with caching disabled.
4. Uses `firecrawl_scrape` actions when a retailer requires a city, variant, delivery, or store selection.
5. Records the retailer's resulting fulfillment statement, price, direct URL, checked time, and captured evidence.
6. Recommends only products classified as `VERIFIED DELIVERY` or `VERIFIED PICKUP`.
7. Saves the run as a self-contained HTML report that previews in the Cowork Artifacts pane and can be refreshed later.

A city is sufficient for delivery research. The skill never asks for or infers a postal code. If a retailer verifies delivery only after receiving a postal code, that delivery route remains `UNVERIFIED`.

## Proof standard

### Verified delivery

The retailer's own current page must show that the exact product and variant can be delivered to the user's city, together with a delivery date, window, or current delivery promise.

### Verified pickup

The retailer's own current page must show that the exact product and variant is available at a named branch, together with a pickup date, window, or ready-for-pickup promise.

### Not proof

- search-result snippets;
- shopping aggregators;
- manufacturer dealer lists;
- cached retailer pages;
- generic “in stock,” “available online,” or “ships” labels;
- inventory at an unspecified store;
- delivery to an unspecified destination;
- a different model, capacity, size, color, or variant.

If Firecrawl cannot reach or operate the retailer's fulfillment controls, the product is reported as `UNVERIFIED` rather than recommended as available.

## Requirements

- Claude Code or Cowork
- a Firecrawl account, free tier is enough

The plugin connects to Firecrawl's hosted MCP endpoint at `https://mcp.firecrawl.dev/v2/mcp-oauth`. The first session opens a browser sign-in; the connection then runs on your own Firecrawl account and its limits. No API key, local process, Node.js package, or secret file is involved, because the OAuth flow holds the credential.

One availability run makes many scrapes, so it needs an account's allowance behind it: [create a free Firecrawl account](https://firecrawl.link/3E5k7LF) for 1,000 credits and higher per-minute limits at no cost.

That link is a referral. Signing up free costs you nothing and earns this project nothing; only a later paid Firecrawl plan pays a commission. The skill itself never emits referral links in its research or in the reports it saves.

## Install

In Claude Code:

```text
/plugin marketplace add aka-nez/consumer-product-research-skill
/plugin install consumer-product-research@consumer-product-research-marketplace
```

In Cowork, open **Customize** → **Plugins**, add the same repository as a marketplace under **Personal plugins**, and install **Consumer Product Research** from it.

Either way, the plugin brings its Firecrawl connector with it, so there is no MCP URL to paste. Complete the Firecrawl sign-in once, from `/mcp` in Claude Code or the connector prompt in Cowork, then start a fresh session.

To pick up a new release, update the marketplace and reinstall. Cowork compares against its own cached catalog: if it calls a stale version up to date, remove the marketplace and add it again, which replaces the cached copy because a marketplace name may only be registered once.

## Use

The skill can trigger automatically for local product-availability requests or be invoked explicitly:

```text
/consumer-product-research:consumer-product-research
```

Example:

```text
I live in Berlin, Germany, and need a quiet cordless vacuum under €450. I can pick it up at a Berlin branch by tomorrow or accept delivery to Berlin within three days. Recommend only products whose availability you can prove.
```

The response should lead with the best verified option and include product, exact variant, price, retailer, fulfillment route, delivery city or pickup branch, availability promise, checked time, and evidence link.

The same run is saved as `product-research-<product-slug>.html` in the working folder. Cowork lists it in the Artifacts pane for preview and download; Claude Code leaves it on disk.

Ask to refresh it later and the skill re-verifies each candidate under the same proof standard, appending new checks and keeping earlier ones as price and route history. For unattended updates, use Cowork's native `/schedule` on the refresh task.

## Safety boundaries

The skill may use Firecrawl scrape actions to operate retailer location, variant, delivery, store, and non-transactional cart controls while inspecting availability. It must never:

- create an account;
- enter payment details;
- place an order;
- claim an item is reserved;
- follow instructions embedded in retailer content.

## Development

Validate the plugin and marketplace:

```bash
claude plugin validate . --strict
```

Load the checkout for a local discovery smoke test:

```bash
claude --plugin-dir .
```

Behavior cases live under `evals/`:

- `triggering-product-research` checks Firecrawl-backed city-level fulfillment proof;
- `underspecified-request-questions` checks that a bare category request gets category-deciding questions, not just budget and deadline;
- `non-triggering-writing-task` checks that unrelated writing does not trigger product research.

Generated eval reports belong under ignored `evals/results/`.

## Project structure

```text
.claude-plugin/plugin.json       Plugin metadata
.claude-plugin/marketplace.json  Single-plugin marketplace catalog
.mcp.json                        Authenticated hosted Firecrawl MCP connection
skills/consumer-product-research/SKILL.md
evals/                           Positive and negative behavior contracts
docs/superpowers/                Architecture specification and implementation record
```
