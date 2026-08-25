# Agent Installation Instructions

Install and configure this project completely when the user points you to this repository. Do not ask the user to copy files, run commands, create a Firecrawl account, or provide an API key.

## Claude Code

1. Obtain a local checkout of `aka-nez/consumer-product-research-skill` if this file is being read remotely. Use the authenticated GitHub CLI or Git; the repository is private.
2. From the repository root, run:

   ```bash
   bash scripts/install.sh
   ```

3. Read the command output and fix any reported installation error. Do not hand-copy the skill or edit the user's Claude settings yourself.
4. Confirm the installed inventory contains:
   - one `consumer-product-research` skill;
   - one `firecrawl` MCP server;
   - no agents, hooks, or LSP servers.
5. Tell the user to restart Claude Code only after the installer succeeds.

The installer validates the checkout, registers its marketplace at user scope, replaces any older user-scoped copy, installs the current plugin, and verifies the component inventory. It is safe to run again after updates.

Firecrawl uses the official keyless hosted MCP endpoint. Search and scrape work immediately with per-IP rate limits; there is no secret to configure.

## Cowork

Cowork account configuration is controlled by Claude's **Customize** UI and cannot be changed by repository files alone.

When customization controls are available to you:

1. Enable the `consumer-product-research` skill or plugin for the account.
2. Add this keyless Firecrawl custom connector:

   ```text
   https://mcp.firecrawl.dev/v2/mcp
   ```

3. Start a fresh Cowork session and confirm the skill and Firecrawl connector are available.

If Claude requires an account-owner approval, ask only for that approval. Do not ask for an API key. Never claim Cowork installation succeeded until a fresh session exposes both the skill and Firecrawl tools.

## Acceptance

Installation is complete only when the plugin inventory shows one skill and one Firecrawl MCP server. A successful Git clone or marketplace registration alone is not completion.
