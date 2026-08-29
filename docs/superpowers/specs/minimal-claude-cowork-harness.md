# Minimal Claude Code and Cowork Harness Design

## Goal

Ship one `consumer-product-research` Agent Skill from this repository and prove that it loads and behaves correctly in Claude Code and Cowork without building a custom runtime.

## Scope

The first release contains:

- one Claude plugin manifest;
- one co-located Claude plugin marketplace catalog;
- one Agent Skill;
- one hosted Firecrawl MCP connection authenticated by the user's own account through browser sign-in;
- static validation with Claude Code's native plugin validator;
- two behavioral eval cases stored in Claude Code's native eval layout;
- a local Claude Code acceptance run;
- a manual Cowork acceptance run using the same skill enabled through claude.ai Customize.
- publication through a Claude plugin marketplace.

The final consumer-product-research methodology can evolve inside `SKILL.md`. This design fixes the packaging, portability, and evaluation contract around it.

## Architecture

```text
consumer-product-research-skill/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .mcp.json
├── skills/
│   └── consumer-product-research/
│       └── SKILL.md
├── evals/
│   ├── triggering-product-research/
│   │   ├── prompt.md
│   │   └── graders/
│   │       └── criteria.md
│   └── non-triggering-writing-task/
│       ├── prompt.md
│       └── graders/
│           └── criteria.md
├── docs/superpowers/
│   ├── specs/
│   │   └── minimal-claude-cowork-harness.md
│   └── plans/
│       └── minimal-claude-cowork-harness.md
└── .gitignore
```

Claude Code can load the checkout directly for development. Users install the published plugin from its marketplace entry in Claude Code or Cowork; there is no repository-side installer, and both harnesses use the same authenticated hosted Firecrawl endpoint.

## Design decisions

### Use the native Agent Skill as the common runtime

`skills/consumer-product-research/SKILL.md` is the only behavior source. Claude Code discovers it from the plugin. Cowork receives the same skill through account sync.

Both harnesses expose the same Firecrawl MCP tool contract: `firecrawl_search` discovers retailer pages, and `firecrawl_scrape` retrieves fresh exact-product evidence and operates dynamic city or store controls through scrape actions.

### Keep the plugin wrapper

The `.claude-plugin/plugin.json` manifest gives the skill a stable namespace, version, display name, and validation target. The default `skills/` directory is auto-discovered; no custom component paths are needed.

### Publish through a co-located marketplace

`.claude-plugin/marketplace.json` lists the root plugin with `"source": "./"`. The catalog has one stable marketplace ID, `consumer-product-research-marketplace`, and one plugin entry, `consumer-product-research`.

The plugin manifest remains authoritative for version and component metadata. The marketplace entry omits a duplicate version, so there is only one value to bump. Because `plugin.json` uses an explicit version, every published update must change that version or existing installations will keep the cached copy.

Local marketplace installation is a separate acceptance path from `--plugin-dir`: it proves Claude Code can copy the plugin from the catalog into its normal cache and still discover the skill. Public hosting uses this same repository after a Git remote exists.

### Do not add a SessionStart hook

A startup bootstrap is necessary for Superpowers because it enforces a methodology across every task. It is unnecessary for one product-research skill: Claude's native skill description already supports automatic and explicit invocation.

Cowork hook execution is not explicitly documented. Depending on a hook would therefore weaken the common Claude Code/Cowork contract and add always-on context cost. Add a hook only if behavioral evals later show that native triggering is inadequate.

### Use one account-authenticated hosted Firecrawl MCP backend

The root `.mcp.json` connects to `https://mcp.firecrawl.dev/v2/mcp-oauth` over HTTP. The client starts a browser sign-in and the user approves a Firecrawl team, so the connection runs on that account's plan and limits. No API key, secret file, environment variable, local process, or plugin configuration is required: Claude stores the OAuth grant per endpoint.

An unauthenticated connection is not an option. One availability run makes many scrapes, and exhausting an allowance mid-run leaves every candidate `UNVERIFIED`, which is a failed run rather than a degraded one.

Dynamic retailer controls use `firecrawl_scrape` actions such as click, write, press, wait, and screenshot. If Firecrawl is unavailable or rate-limited, the skill must stop rather than downgrade availability proof to generic search, and must hand back the fix for that specific failure instead of only the failure.

The hosted transport avoids `npx`, a local MCP process, Node.js, and runtime package dependencies.

The skill must not depend on:

- `!` dynamic shell commands, which Cowork disables for user-supplied skills;
- local absolute paths;
- `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_SESSION_ID}` substitutions;
- plugin executables;
- subagents or a particular task-list tool.

### Use no build system or runtime dependencies

The repository needs no `package.json`, lockfile, compiler, framework, local server, or generated artifact. Claude Code consumes the JSON manifests and Markdown skill directly and calls Firecrawl's hosted MCP service.

### Keep evals in this repository

A separate Quorum-style eval repository, container, scheduler, dashboard, credential registry, and transcript normalizer are unnecessary for one skill and one harness family. Split eval infrastructure only after a second genuinely different harness or enough paid scenarios make isolation worthwhile.

### Use Claude's native plugin-eval file layout

Eval cases live under `evals/**/prompt.md` with Markdown graders under `graders/`. Claude Code 2.1.245 advertises `claude plugin eval`, including plugin/no-plugin ablation, multiple runs, cost ceilings, and HTML/JSON reports.

The installed CLI currently reports that `plugin eval` is in early access for this account. The files should still use its native layout. Until access is enabled, the same prompts and criteria are run manually in Claude Code and Cowork. Do not build a replacement eval framework for this temporary gate.

## Current skill contract

The skill exists to find products that can actually be fulfilled for the user:

1. Trigger for local product searches and recommendations that depend on delivery or pickup availability.
2. Require country and city, budget, and fulfillment deadline before checking stock; never ask for or infer a postal code.
3. Require Firecrawl search and scrape tools; on failure, stop and return the matching remedy: sign in for an unauthenticated or rate-limited connection, with the disclosed free-signup link when the user has no account; a reset notice for a spent account allowance; a connector check for missing tools.
4. Use `firecrawl_search` with the user's geographic location to discover retailer pages.
5. Use search results and aggregators only as leads; never treat them as availability evidence.
6. Use fresh `firecrawl_scrape` requests with `maxAge: 0` and `storeInCache: false` on the exact retailer product.
7. Use `firecrawl_scrape` actions when a city, variant, delivery, or store selector controls fulfillment state.
8. Match the exact product and variant on the retailer's own current site.
9. Verify delivery with a destination-specific promise, or pickup with a branch-specific ready date or window.
10. Record the availability statement, branch/address or delivery city, promise, price, direct URL, checked time, and captured post-selection evidence.
11. Label candidates `VERIFIED DELIVERY`, `VERIFIED PICKUP`, or `UNVERIFIED`, recommend only verified candidates, and report honestly when none can be proved.

Generic “in stock,” unspecified-store stock, unspecified-destination shipping, snippets, dealer lists, and third-party marketplace claims are not proof.

## Behavioral eval contract

### Triggering case

Prompt: a shopping request with a city, delivery/pickup deadline, and budget that does not mention skills or Superpowers and explicitly rejects postal-code questions.

Pass when the plugin arm:

- invokes or clearly follows the availability-proof workflow;
- uses Firecrawl search plus fresh scrape or interaction evidence in the trace;
- recommends only exact products with location-specific first-party delivery or pickup evidence;
- records the retailer, destination or branch, availability promise, price, URL, and checked time;
- labels insufficiently supported candidates `UNVERIFIED`; and
- reports no verified option when proof cannot be obtained.

The no-plugin arm establishes whether the skill materially improves fulfillment verification rather than merely producing a plausible product list.

### Non-triggering case

Prompt: an unrelated writing request.

Pass when the skill does not inject a shopping workflow, product shortlist, web research, or citations into the response. This guards against an over-broad description that triggers on ordinary writing tasks.

## Distribution

### Claude Code development

Load the checkout directly:

```bash
claude --plugin-dir .
```

Validate it with:

```bash
claude plugin validate . --strict
```

### Marketplace installation

Users install the plugin from its marketplace entry, in Claude Code with `/plugin marketplace add` plus `/plugin install`, or in Cowork by adding the same repository under **Customize** → **Plugins**. The repository ships no installer: an installation path that only worked from a local checkout was dead weight once the plugin is published.

Both paths carry the plugin's own `.mcp.json`, so no MCP URL is pasted by hand. The user then completes the Firecrawl browser sign-in, from `/mcp` in Claude Code or the connector prompt in Cowork. No script can perform that step, and no API key is requested.

An account-owner approval in **Customize** may be required for Cowork; repository files cannot bypass that platform boundary.

## Acceptance criteria

- `claude plugin validate . --strict` succeeds without warnings.
- `.claude-plugin/marketplace.json` exposes exactly one root plugin as `consumer-product-research@consumer-product-research-marketplace`.
- Installing the published plugin yields version `0.6.0`.
- `.mcp.json` declares exactly one hosted HTTP server named `firecrawl`, pointing at the OAuth endpoint.
- Installed plugin inventory lists one skill and one Firecrawl MCP server.
- No tracked file contains or requests a Firecrawl API key; the connection authenticates by browser sign-in.
- `README.md` states the marketplace install and the one-time Firecrawl sign-in.
- Claude Code lists `/consumer-product-research:consumer-product-research` when the checkout is loaded with `--plugin-dir .`.
- Explicit invocation follows the workflow.
- Every recommendation includes first-party proof for delivery to the user's city or pickup at a named local branch.
- The skill never asks for or infers a postal code; postal-code-only delivery checks remain `UNVERIFIED`.
- Search snippets, generic stock labels, unspecified fulfillment, and unverified variants never qualify as proof.
- A fresh Claude Code session automatically applies the skill to the triggering prompt.
- A fresh Claude Code session does not apply the skill to the non-triggering prompt.
- The exact same two prompts produce equivalent trigger/non-trigger behavior in a fresh Cowork session with the account-synced skill enabled.
- The skill contains no shell expansion, local-path dependency, executable, hook, or runtime package.
- Eval outputs remain untracked under `evals/results/`.
