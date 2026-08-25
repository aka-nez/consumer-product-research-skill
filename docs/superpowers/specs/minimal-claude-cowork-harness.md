# Minimal Claude Code and Cowork Harness Design

## Goal

Ship one `consumer-product-research` Agent Skill from this repository and prove that it loads and behaves correctly in Claude Code and Cowork without building a custom runtime.

## Scope

The first release contains:

- one Claude plugin manifest;
- one co-located Claude plugin marketplace catalog;
- one Agent Skill;
- one keyless hosted Firecrawl MCP connection that works without an account or secret;
- static validation with Claude Code's native plugin validator;
- two behavioral eval cases stored in Claude Code's native eval layout;
- a local Claude Code acceptance run;
- a manual Cowork acceptance run using the same skill enabled through claude.ai Customize.
- one idempotent agent-executable Claude Code installer;
- agent-facing `CLAUDE.md` and `INSTALL.md` instructions.

The final consumer-product-research methodology can evolve inside `SKILL.md`. This design fixes the packaging, portability, and evaluation contract around it.

## Architecture

```text
consumer-product-research-skill/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .mcp.json
├── CLAUDE.md
├── INSTALL.md
├── scripts/
│   └── install.sh
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

Claude Code can load the checkout directly, but normal installation is agent-first: `CLAUDE.md` routes the agent to `INSTALL.md`, and `scripts/install.sh` validates, registers, installs, and verifies the plugin at user scope. Cowork uses account-enabled customizations and the same keyless hosted Firecrawl endpoint.

## Design decisions

### Use the native Agent Skill as the common runtime

`skills/consumer-product-research/SKILL.md` is the only behavior source. Claude Code discovers it from the plugin. Cowork receives the same skill through account sync.

Both harnesses expose the same keyless Firecrawl MCP tool contract: `firecrawl_search` discovers retailer pages, and `firecrawl_scrape` retrieves fresh exact-product evidence and operates dynamic city or store controls through scrape actions.

### Keep the plugin wrapper

The `.claude-plugin/plugin.json` manifest gives the skill a stable namespace, version, display name, and validation target. The default `skills/` directory is auto-discovered; no custom component paths are needed.

### Publish through a co-located marketplace

`.claude-plugin/marketplace.json` lists the root plugin with `"source": "./"`. The catalog has one stable marketplace ID, `consumer-product-research-marketplace`, and one plugin entry, `consumer-product-research`.

The plugin manifest remains authoritative for version and component metadata. The marketplace entry omits a duplicate version, so there is only one value to bump. Because `plugin.json` uses an explicit version, every published update must change that version or existing installations will keep the cached copy.

Local marketplace installation is a separate acceptance path from `--plugin-dir`: it proves Claude Code can copy the plugin from the catalog into its normal cache and still discover the skill. Public hosting uses this same repository after a Git remote exists.

### Do not add a SessionStart hook

A startup bootstrap is necessary for Superpowers because it enforces a methodology across every task. It is unnecessary for one product-research skill: Claude's native skill description already supports automatic and explicit invocation.

Cowork hook execution is not explicitly documented. Depending on a hook would therefore weaken the common Claude Code/Cowork contract and add always-on context cost. Add a hook only if behavioral evals later show that native triggering is inadequate.

### Use one keyless hosted Firecrawl MCP backend

The root `.mcp.json` connects to `https://mcp.firecrawl.dev/v2/mcp` over HTTP. Firecrawl exposes search and scrape without an account or API key, rate-limited per IP. No secret, environment variable, local process, or plugin configuration is required.

Dynamic retailer controls use `firecrawl_scrape` actions such as click, write, press, wait, and screenshot. If Firecrawl is unavailable or rate-limited, the skill must stop rather than downgrade availability proof to generic search.

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
3. Require Firecrawl search and scrape tools; stop if they are unavailable or rate-limited.
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

### Agent-first Claude Code installation

When a user points an agent at the repository, root `CLAUDE.md` instructs it to execute `INSTALL.md`. The agent runs:

```bash
bash scripts/install.sh
```

The installer:

1. validates the checkout with `claude plugin validate --strict`;
2. registers `aka-nez/consumer-product-research-skill` as a user-scope marketplace;
3. removes only an older user-scoped copy of this plugin;
4. installs the current plugin;
5. verifies one skill and one Firecrawl MCP server are present.

It is idempotent and requests no Firecrawl credential. The only allowed user interaction is Claude's own trust or MCP approval.

### Marketplace development

Set `CONSUMER_PRODUCT_RESEARCH_MARKETPLACE_SOURCE` to the current checkout when testing an unmerged branch:

```bash
CONSUMER_PRODUCT_RESEARCH_MARKETPLACE_SOURCE="$PWD" bash scripts/install.sh
```

Normal installations omit the override and track the private GitHub repository.

### Cowork installation

Cowork sessions load account-synced customizations rather than the local Claude Code installation. When customization controls are available, the agent enables the skill and adds `https://mcp.firecrawl.dev/v2/mcp` as a custom connector.

An account-owner approval in **Customize** may be required; repository files cannot bypass that platform boundary. No API key is requested.

## Acceptance criteria

- `claude plugin validate . --strict` succeeds without warnings.
- `.claude-plugin/marketplace.json` exposes exactly one root plugin as `consumer-product-research@consumer-product-research-marketplace`.
- The autonomous installer succeeds repeatedly in an isolated home and installs version `0.4.0`.
- `.mcp.json` declares exactly one keyless hosted HTTP server named `firecrawl`.
- Installed plugin inventory lists one skill and one Firecrawl MCP server.
- No tracked file contains or requests a Firecrawl API key.
- `INSTALL.md` lets an agent complete Claude Code setup without asking the user to copy files or run commands.
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
