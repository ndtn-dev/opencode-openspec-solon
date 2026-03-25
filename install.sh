#!/bin/bash
set -euo pipefail

PLATFORM=${1:-}
SCOPE=${2:-local}

usage() {
  echo "Usage: ./install.sh <claude|opencode> [--global]"
  echo ""
  echo "Copies Solon agent and skills to the appropriate config directory."
  echo ""
  echo "  claude    -> .claude/agents/ and .claude/skills/"
  echo "  opencode  -> .opencode/agents/ and .opencode/skills/"
  echo ""
  echo "  --global  Install to ~/.claude/ or ~/.config/opencode/ (available in all projects)"
  echo "            Also adds a 'solon' shell alias for claude --agent solon"
  echo "  (default) Install to current directory (project-local)"
  exit 1
}

if [[ -z "$PLATFORM" ]]; then
  usage
fi

if [[ "$SCOPE" == "--global" ]]; then
  GLOBAL=true
else
  GLOBAL=false
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_alias() {
  local alias_line="alias solon='claude --agent solon'"
  local fish_line="alias solon 'claude --agent solon'"
  local added=false

  # zsh
  if [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -qF "alias solon=" "$HOME/.zshrc" 2>/dev/null; then
      echo "" >> "$HOME/.zshrc"
      echo "# Solon — OpenSpec design partner" >> "$HOME/.zshrc"
      echo "$alias_line" >> "$HOME/.zshrc"
      echo "  Added alias to ~/.zshrc"
      added=true
    else
      echo "  Alias already in ~/.zshrc"
    fi
  fi

  # bash
  if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -qF "alias solon=" "$HOME/.bashrc" 2>/dev/null; then
      echo "" >> "$HOME/.bashrc"
      echo "# Solon — OpenSpec design partner" >> "$HOME/.bashrc"
      echo "$alias_line" >> "$HOME/.bashrc"
      echo "  Added alias to ~/.bashrc"
      added=true
    else
      echo "  Alias already in ~/.bashrc"
    fi
  fi

  # fish
  local fish_conf="$HOME/.config/fish/config.fish"
  if [[ -f "$fish_conf" ]]; then
    if ! grep -qF "alias solon " "$fish_conf" 2>/dev/null; then
      echo "" >> "$fish_conf"
      echo "# Solon — OpenSpec design partner" >> "$fish_conf"
      echo "$fish_line" >> "$fish_conf"
      echo "  Added alias to $fish_conf"
      added=true
    else
      echo "  Alias already in $fish_conf"
    fi
  fi

  if $added; then
    echo "  Restart your shell or run: source ~/.zshrc (or equivalent)"
  fi
}

case "$PLATFORM" in
  claude)
    if $GLOBAL; then
      TARGET="$HOME/.claude"
    else
      TARGET=".claude"
    fi
    mkdir -p "$TARGET/agents" "$TARGET/skills"
    cp "$SCRIPT_DIR/claude/agent/solon.md" "$TARGET/agents/solon.md"
    for skill_dir in "$SCRIPT_DIR"/claude/skills/*/; do
      skill_name=$(basename "$skill_dir")
      mkdir -p "$TARGET/skills/$skill_name"
      cp "$skill_dir"SKILL.md "$TARGET/skills/$skill_name/SKILL.md"
    done
    echo "Installed Solon for Claude Code ($TARGET/):"
    echo "  $TARGET/agents/solon.md"
    for skill_dir in "$SCRIPT_DIR"/claude/skills/*/; do
      echo "  $TARGET/skills/$(basename "$skill_dir")/SKILL.md"
    done
    if $GLOBAL; then
      echo ""
      echo "Shell alias:"
      install_alias
    fi
    ;;
  opencode)
    if $GLOBAL; then
      TARGET="$HOME/.config/opencode"
    else
      TARGET=".opencode"
    fi
    mkdir -p "$TARGET/agents" "$TARGET/skills"
    cp "$SCRIPT_DIR/opencode/agent/solon.md" "$TARGET/agents/solon.md"
    for skill_dir in "$SCRIPT_DIR"/opencode/skills/*/; do
      skill_name=$(basename "$skill_dir")
      mkdir -p "$TARGET/skills/$skill_name"
      cp "$skill_dir"SKILL.md "$TARGET/skills/$skill_name/SKILL.md"
    done
    echo "Installed Solon for OpenCode ($TARGET/):"
    echo "  $TARGET/agents/solon.md"
    echo "  $TARGET/skills/ ($(ls -d "$SCRIPT_DIR"/opencode/skills/*/ | wc -l) skills)"
    ;;
  *)
    echo "Unknown platform: $PLATFORM"
    usage
    ;;
esac
