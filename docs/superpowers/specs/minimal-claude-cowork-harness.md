# Minimal Claude Code and Cowork Harness Design

## Goal

Ship one `consumer-product-research` Agent Skill from this repository and prove that it loads and behaves correctly in Claude Code and Cowork without building a custom runtime.

## Scope

The first release contains:

- one Claude plugin manifest;
- one co-located Claude plugin marketplace catalog;
- one Agent Skill;
- one hosted Firecrawl MCP connection configured through a required sensitive API-key option;
- static validation with Claude Code's native plugin validator;
- two behavioral eval cases stored in Claude Code's native eval layout;
- a local Claude Code acceptance run;
- a manual Cowork acceptance run using the same skill enabled through claude.ai Customize.

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

Claude Code loads the repository as a plugin with `claude --plugin-dir .`; the plugin connects to Firecrawl's hosted HTTP MCP server. Cowork does not read the local plugin directory or `~/.claude/skills`; it loads account-enabled customizations and must connect to the same hosted Firecrawl MCP endpoint.

## Design decisions

### Use the native Agent Skill as the common runtime

`skills/consumer-product-research/SKILL.md` is the only behavior source. Claude Code discovers it from the plugin. Cowork receives the same skill through account sync.

Both harnesses expose the same Firecrawl MCP tool contract: `firecrawl_search` discovers retailer pages, `firecrawl_scrape` retrieves fresh exact-product evidence, and `firecrawl_interact` operates dynamic postcode and store selectors.

### Keep the plugin wrapper

The `.claude-plugin/plugin.json` manifest gives the skill a stable namespace, version, display name, and validation target. The default `skills/` directory is auto-discovered; no custom component paths are needed.

### Publish through a co-located marketplace

`.claude-plugin/marketplace.json` lists the root plugin with `"source": "./"`. The catalog has one stable marketplace ID, `consumer-product-research-marketplace`, and one plugin entry, `consumer-product-research`.

The plugin manifest remains authoritative for version and component metadata. The marketplace entry omits a duplicate version, so there is only one value to bump. Because `plugin.json` uses an explicit version, every published update must change that version or existing installations will keep the cached copy.

Local marketplace installation is a separate acceptance path from `--plugin-dir`: it proves Claude Code can copy the plugin from the catalog into its normal cache and still discover the skill. Public hosting uses this same repository after a Git remote exists.

### Do not add a SessionStart hook

A startup bootstrap is necessary for Superpowers because it enforces a methodology across every task. It is unnecessary for one product-research skill: Claude's native skill description already supports automatic and explicit invocation.

Cowork hook execution is not explicitly documented. Depending on a hook would therefore weaken the common Claude Code/Cowork contract and add always-on context cost. Add a hook only if behavioral evals later show that native triggering is inadequate.

### Use one hosted Firecrawl MCP backend

The root `.mcp.json` connects to `https://mcp.firecrawl.dev/<key>/v2/mcp` over HTTP. The plugin manifest declares `firecrawl_api_key` as required and sensitive, and `.mcp.json` substitutes `${user_config.firecrawl_api_key}` into the URL. No API key is committed to Git or written to project settings.

Claude Code prompts for the key when the plugin is enabled and stores it in secure user configuration. Cowork must configure the same hosted Firecrawl endpoint as an account connector because it cannot inherit local plugin configuration or environment variables.

The hosted transport avoids `npx`, a local MCP process, Node.js, and a runtime package dependency. If Firecrawl is missing or unauthenticated, the skill must stop rather than downgrade availability proof to generic search.

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
2. Require country plus postal code or city, pickup radius, budget, and fulfillment deadline before checking stock.
3. Require authenticated Firecrawl tools; stop if they are unavailable.
4. Use `firecrawl_search` with the user's geographic location to discover retailer pages.
5. Use search results and aggregators only as leads; never treat them as availability evidence.
6. Use fresh `firecrawl_scrape` requests with `maxAge: 0` and `storeInCache: false` on the exact retailer product.
7. Use `firecrawl_interact` when a postcode, variant, delivery, or store selector controls fulfillment state.
8. Match the exact product and variant on the retailer's own current site.
9. Verify delivery with a destination-specific promise, or pickup with a branch-specific ready date or window.
10. Record the availability statement, branch/address or postal code, promise, price, direct URL, checked time, and captured post-selection evidence.
11. Label candidates `VERIFIED DELIVERY`, `VERIFIED PICKUP`, or `UNVERIFIED`, recommend only verified candidates, and report honestly when none can be proved.

Generic “in stock,” unspecified-store stock, unspecified-destination shipping, snippets, dealer lists, and third-party marketplace claims are not proof.

## Behavioral eval contract

### Triggering case

Prompt: a shopping request with a postal code, pickup radius, delivery/pickup deadline, and budget that does not mention skills or Superpowers.

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

### Marketplace development

Validate the co-located plugin and marketplace together:

```bash
claude plugin validate . --strict
```

Register and install the local catalog at local scope:

```bash
claude plugin marketplace add ./ --scope local
claude plugin install consumer-product-research@consumer-product-research-marketplace --scope local
claude plugin details consumer-product-research@consumer-product-research-marketplace
```

Installation prompts for the required Firecrawl API key. Enter it only through Claude's masked plugin configuration; do not place it in the repository, shell command, or project settings.

The local-scope settings file is development state and remains untracked. After the repository has a GitHub origin, users register that `owner/repository` source and install the same namespaced plugin. No second marketplace repository or copied plugin tree is needed.

### Cowork development

Cowork sessions load account-synced customizations rather than the local CLI directory. Enable the same skill for the test account through **Customize** in Claude Desktop or the skill settings on claude.ai, then start a fresh Cowork session.

Add Firecrawl's hosted MCP endpoint as a Cowork custom connector using the account's API key in the documented URL form `https://mcp.firecrawl.dev/<key>/v2/mcp`. The marketplace is the Claude Code and Desktop Code distribution channel; it does not transfer local plugin secrets into Cowork.

## Acceptance criteria

- `claude plugin validate . --strict` succeeds without warnings.
- `.claude-plugin/marketplace.json` exposes exactly one root plugin as `consumer-product-research@consumer-product-research-marketplace`.
- A local-scope marketplace registration and install succeeds, and `claude plugin details consumer-product-research@consumer-product-research-marketplace` lists the skill.
- `.mcp.json` declares exactly one hosted HTTP server named `firecrawl`.
- The Firecrawl API key is a required sensitive `userConfig` value and is absent from tracked files.
- Installed plugin inventory lists one Firecrawl MCP server.
- Claude Code lists `/consumer-product-research:consumer-product-research` when the checkout is loaded with `--plugin-dir .`.
- Explicit invocation follows the workflow.
- Every recommendation includes first-party, location-specific proof for delivery to the user's postal code or pickup at a named local branch.
- Search snippets, generic stock labels, unspecified fulfillment, and unverified variants never qualify as proof.
- A fresh Claude Code session automatically applies the skill to the triggering prompt.
- A fresh Claude Code session does not apply the skill to the non-triggering prompt.
- The exact same two prompts produce equivalent trigger/non-trigger behavior in a fresh Cowork session with the account-synced skill enabled.
- The skill contains no shell expansion, local-path dependency, executable, hook, or runtime package.
- Eval outputs remain untracked under `evals/results/`.
