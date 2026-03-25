#!/bin/bash
set -euo pipefail

PLATFORM=${1:-}

usage() {
  echo "Usage: ./install.sh <claude|opencode>"
  echo ""
  echo "Copies Solon agent and skills to the appropriate config directory."
  echo ""
  echo "  claude    -> .claude/agents/ and .claude/skills/"
  echo "  opencode  -> .opencode/agents/ and .opencode/skills/"
  exit 1
}

if [[ -z "$PLATFORM" ]]; then
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$PLATFORM" in
  claude)
    mkdir -p .claude/agents .claude/skills
    cp "$SCRIPT_DIR/claude/agent/solon.md" .claude/agents/solon.md
    for skill_dir in "$SCRIPT_DIR"/claude/skills/*/; do
      skill_name=$(basename "$skill_dir")
      mkdir -p ".claude/skills/$skill_name"
      cp "$skill_dir"SKILL.md ".claude/skills/$skill_name/SKILL.md"
    done
    echo "Installed Solon for Claude Code:"
    echo "  .claude/agents/solon.md"
    echo "  .claude/skills/solon-spec/SKILL.md"
    echo "  .claude/skills/solon-init/SKILL.md"
    echo "  .claude/skills/solon-handoff/SKILL.md"
    echo "  .claude/skills/solon-reconcile/SKILL.md"
    echo "  .claude/skills/solon-ingress/SKILL.md"
    echo "  .claude/skills/graphiti-ledger-status/SKILL.md"
    ;;
  opencode)
    mkdir -p .opencode/agents .opencode/skills
    cp "$SCRIPT_DIR/opencode/agent/solon.md" .opencode/agents/solon.md
    for skill_dir in "$SCRIPT_DIR"/opencode/skills/*/; do
      skill_name=$(basename "$skill_dir")
      mkdir -p ".opencode/skills/$skill_name"
      cp "$skill_dir"SKILL.md ".opencode/skills/$skill_name/SKILL.md"
    done
    echo "Installed Solon for OpenCode:"
    echo "  .opencode/agents/solon.md"
    echo "  .opencode/skills/ (6 skills)"
    ;;
  *)
    echo "Unknown platform: $PLATFORM"
    usage
    ;;
esac
