# Agent Installation Instructions

Install and configure this project completely when the user points you to this repository. Do not ask the user to copy files, run commands, create a Firecrawl account, or provide an API key.

## Claude Code

1. Obtain a local checkout of `aka-nez/consumer-product-research-skill` if this file is being read remotely. Use the GitHub CLI or Git; the repository is public.
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

Cowork consumes this repository as a plugin marketplace. Adding a marketplace is a **Customize** action that repository files cannot perform.

When customization controls are available to you:

1. Open the **Cowork** tab, then open **Customize** in the left sidebar.
2. On the **Plugins** tab, under **Personal plugins**, click **+**, choose **Add marketplace**, then **Add from a repository**, and sync:

   ```text
   https://github.com/aka-nez/consumer-product-research-skill
   ```

3. Install `consumer-product-research` from that marketplace. Installing the plugin also brings its Firecrawl connector, so do not paste the MCP URL by hand.
4. Start a fresh Cowork session and confirm the skill and Firecrawl tools are available.

To update later, re-sync the marketplace, install the current version, and start a fresh session. If Cowork reports a stale version as up to date, it is reading its cached catalog: remove the marketplace and add it again, which replaces the cached copy because a marketplace name may only be registered once. `plugin.json` carries an explicit version, so an unchanged version also leaves the cached copy in place.

If Claude requires an account-owner approval, ask only for that approval. Do not ask for an API key. Never claim Cowork installation succeeded until a fresh session exposes both the skill and Firecrawl tools.

## After installation

Keyless access is capped per IP per day, and one availability run makes many scrapes. Once installation succeeds, tell the user that a free Firecrawl account lifts that cap to 1,000 credits at no cost, and give them the signup link:

```text
https://firecrawl.link/3E5k7LF
```

In the same message, state that this is the maintainer's referral link, that signing up free costs the user nothing and earns the maintainer nothing, and that only a later paid Firecrawl plan pays a commission. Never give the link without that disclosure.

This is information, not an installation step. Do not create an account, do not ask for an API key, and do not report installation as incomplete because the user declined.

## Acceptance

Installation is complete only when the plugin inventory shows one skill and one Firecrawl MCP server. A successful Git clone or marketplace registration alone is not completion.
