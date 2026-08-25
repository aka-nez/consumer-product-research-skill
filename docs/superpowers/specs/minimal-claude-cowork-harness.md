# Minimal Claude Code and Cowork Harness Design

## Goal

Ship one `consumer-product-research` Agent Skill from this repository and prove that it loads and behaves correctly in Claude Code and Cowork without building a custom runtime.

## Scope

The first release contains:

- one Claude plugin manifest;
- one co-located Claude plugin marketplace catalog;
- one Agent Skill;
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

Claude Code loads the repository as a plugin with `claude --plugin-dir .`. Cowork does not read the local plugin directory or `~/.claude/skills`; it loads the skill or plugin enabled for the user's claude.ai account at session start.

## Design decisions

### Use the native Agent Skill as the common runtime

`skills/consumer-product-research/SKILL.md` is the only behavior source. Claude Code discovers it from the plugin. Cowork receives the same skill through account sync.

The skill describes actions rather than harness-specific tool names: search the web, inspect primary sources, compare evidence, and report uncertainty. This avoids separate Claude Code and Cowork variants.

### Keep the plugin wrapper

The `.claude-plugin/plugin.json` manifest gives the skill a stable namespace, version, display name, and validation target. The default `skills/` directory is auto-discovered; no custom component paths are needed.

### Publish through a co-located marketplace

`.claude-plugin/marketplace.json` lists the root plugin with `"source": "./"`. The catalog has one stable marketplace ID, `consumer-product-research-marketplace`, and one plugin entry, `consumer-product-research`.

The plugin manifest remains authoritative for version and component metadata. The marketplace entry omits a duplicate version, so there is only one value to bump. Because `plugin.json` uses an explicit version, every published update must change that version or existing installations will keep the cached copy.

Local marketplace installation is a separate acceptance path from `--plugin-dir`: it proves Claude Code can copy the plugin from the catalog into its normal cache and still discover the skill. Public hosting uses this same repository after a Git remote exists.

### Do not add a SessionStart hook

A startup bootstrap is necessary for Superpowers because it enforces a methodology across every task. It is unnecessary for one product-research skill: Claude's native skill description already supports automatic and explicit invocation.

Cowork hook execution is not explicitly documented. Depending on a hook would therefore weaken the common Claude Code/Cowork contract and add always-on context cost. Add a hook only if behavioral evals later show that native triggering is inadequate.

### Avoid Cowork-incompatible skill features

The initial skill must not depend on:

- `!` dynamic shell commands, which Cowork disables for user-supplied skills;
- local absolute paths;
- `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_SESSION_ID}` substitutions;
- an MCP server;
- plugin executables;
- subagents or a particular task-list tool.

Built-in web research capabilities are sufficient for the first version. Add an MCP connector only when a required product data source cannot be reached reliably through normal web research.

### Use no build system or runtime dependencies

The repository needs no `package.json`, lockfile, compiler, framework, server, or generated artifact. Claude Code consumes the JSON manifest and Markdown skill directly.

### Keep evals in this repository

A separate Quorum-style eval repository, container, scheduler, dashboard, credential registry, and transcript normalizer are unnecessary for one skill and one harness family. Split eval infrastructure only after a second genuinely different harness or enough paid scenarios make isolation worthwhile.

### Use Claude's native plugin-eval file layout

Eval cases live under `evals/**/prompt.md` with Markdown graders under `graders/`. Claude Code 2.1.245 advertises `claude plugin eval`, including plugin/no-plugin ablation, multiple runs, cost ceilings, and HTML/JSON reports.

The installed CLI currently reports that `plugin eval` is in early access for this account. The files should still use its native layout. Until access is enabled, the same prompts and criteria are run manually in Claude Code and Cowork. Do not build a replacement eval framework for this temporary gate.

## Initial skill contract

The first `SKILL.md` is a complete, small workflow:

1. Use the skill for product recommendations, comparisons, shortlists, buying decisions, and verification of current product claims.
2. Ask only for missing constraints that could change the recommendation; otherwise state reasonable assumptions and proceed.
3. Research current candidates rather than relying on memory.
4. Prefer manufacturer documentation for specifications and warranty, current retailers for price and availability, and independent sources for measured performance or reliability.
5. Exclude candidates that violate hard constraints.
6. Compare three to five viable finalists on decision-relevant criteria.
7. Separate verified facts, source-reported observations, and inference.
8. Recommend one primary choice and one alternative, with decisive tradeoffs, current pricing context, citations, and unverified points.

## Behavioral eval contract

### Triggering case

Prompt: a realistic shopping request that does not mention research, skills, or Superpowers.

Pass when the plugin arm:

- invokes or clearly follows the consumer-product-research workflow;
- gathers current evidence;
- respects the user's hard constraints;
- distinguishes source types and uncertainty;
- produces a useful recommendation with citations.

The no-plugin arm establishes whether the skill materially improves the result rather than merely producing a plausible answer.

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

The local-scope settings file is development state and remains untracked. After the repository has a GitHub origin, users register that `owner/repository` source and install the same namespaced plugin. No second marketplace repository or copied plugin tree is needed.

### Cowork development

Cowork sessions load account-synced customizations rather than the local CLI directory. Enable the same skill for the test account through **Customize** in Claude Desktop or the skill settings on claude.ai, then start a fresh Cowork session.

The marketplace is the Claude Code and Desktop Code distribution channel. It does not make a local installation available in Cowork: Cowork still requires the skill or plugin to be enabled for the claude.ai account. Organization-managed marketplace distribution remains a later option for Team or Enterprise deployment.

## Acceptance criteria

- `claude plugin validate . --strict` succeeds without warnings.
- `.claude-plugin/marketplace.json` exposes exactly one root plugin as `consumer-product-research@consumer-product-research-marketplace`.
- A local-scope marketplace registration and install succeeds, and `claude plugin details consumer-product-research@consumer-product-research-marketplace` lists the skill.
- Claude Code lists `/consumer-product-research:consumer-product-research` when the checkout is loaded with `--plugin-dir .`.
- Explicit invocation follows the workflow.
- A fresh Claude Code session automatically applies the skill to the triggering prompt.
- A fresh Claude Code session does not apply the skill to the non-triggering prompt.
- The exact same two prompts produce equivalent trigger/non-trigger behavior in a fresh Cowork session with the account-synced skill enabled.
- The skill contains no shell expansion, local-path dependency, MCP dependency, executable, hook, or runtime package.
- Eval outputs remain untracked under `evals/results/`.
