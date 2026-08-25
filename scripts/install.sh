#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE_SOURCE="${CONSUMER_PRODUCT_RESEARCH_MARKETPLACE_SOURCE:-aka-nez/consumer-product-research-skill}"
MARKETPLACE_ID="consumer-product-research-marketplace"
PLUGIN_ID="consumer-product-research@${MARKETPLACE_ID}"

if ! command -v claude >/dev/null 2>&1; then
  printf '%s\n' "error: Claude Code is required: https://code.claude.com/docs/en/setup" >&2
  exit 1
fi

printf '%s\n' "Validating plugin..."
claude plugin validate "$ROOT" --strict

printf '%s\n' "Registering marketplace: $MARKETPLACE_SOURCE"
claude plugin marketplace add "$MARKETPLACE_SOURCE" --scope user

# Reinstalling this plugin's user-scoped copy is deterministic and keeps the
# installer idempotent without parsing Claude Code's human-readable output.
claude plugin uninstall "$PLUGIN_ID" --scope user >/dev/null 2>&1 || true

printf '%s\n' "Installing plugin..."
claude plugin install "$PLUGIN_ID" --scope user

printf '%s\n' "Verifying installed components..."
details="$(claude plugin details "$PLUGIN_ID")"
printf '%s\n' "$details"

case "$details" in
  *"Skills (1)"*"MCP servers (1)"*"firecrawl"*) ;;
  *)
    printf '%s\n' "error: installed plugin is missing its skill or Firecrawl MCP server" >&2
    exit 1
    ;;
esac

printf '%s\n' \
  "Installed $PLUGIN_ID." \
  "Firecrawl search and scrape are ready with no API key." \
  "Restart Claude Code, then use /consumer-product-research:consumer-product-research."
