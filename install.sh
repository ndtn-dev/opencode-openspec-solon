#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSPEC_MIN_NODE="20.19.0"

# ── Helpers ──────────────────────────────────────────────────────────

version_gte() {
  # returns 0 (true) if $1 >= $2
  printf '%s\n%s' "$2" "$1" | sort -V -C
}

CHOICE=0
prompt_choice() {
  local prompt="$1"
  shift
  local options=("$@")

  echo ""
  echo "$prompt"
  for i in "${!options[@]}"; do
    echo "  $((i + 1))) ${options[$i]}"
  done

  local choice
  while true; do
    read -rp "> " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      CHOICE=$((choice - 1))
      return 0
    fi
    echo "  Please enter a number between 1 and ${#options[@]}"
  done
}

# ── Install functions ────────────────────────────────────────────────

install_alias() {
  local alias_line="alias solon='claude --agent solon --effort max'"
  local fish_line="alias solon 'claude --agent solon --effort max'"
  local added_shells=()

  # zsh
  if [[ -f "$HOME/.zshrc" ]]; then
    if grep -qF "alias solon=" "$HOME/.zshrc" 2>/dev/null; then
      sed -i "s|alias solon=.*|$alias_line|" "$HOME/.zshrc"
      echo "  Updated alias in ~/.zshrc"
    else
      echo "" >> "$HOME/.zshrc"
      echo "# Solon — OpenSpec design partner" >> "$HOME/.zshrc"
      echo "$alias_line" >> "$HOME/.zshrc"
      echo "  Added alias to ~/.zshrc"
    fi
    added_shells+=("zsh")
  fi

  # bash
  if [[ -f "$HOME/.bashrc" ]]; then
    if grep -qF "alias solon=" "$HOME/.bashrc" 2>/dev/null; then
      sed -i "s|alias solon=.*|$alias_line|" "$HOME/.bashrc"
      echo "  Updated alias in ~/.bashrc"
    else
      echo "" >> "$HOME/.bashrc"
      echo "# Solon — OpenSpec design partner" >> "$HOME/.bashrc"
      echo "$alias_line" >> "$HOME/.bashrc"
      echo "  Added alias to ~/.bashrc"
    fi
    added_shells+=("bash")
  fi

  # fish
  local fish_conf="$HOME/.config/fish/config.fish"
  if [[ -f "$fish_conf" ]]; then
    if grep -qF "alias solon " "$fish_conf" 2>/dev/null; then
      sed -i "s|alias solon .*|$fish_line|" "$fish_conf"
      echo "  Updated alias in $fish_conf"
    else
      echo "" >> "$fish_conf"
      echo "# Solon — OpenSpec design partner" >> "$fish_conf"
      echo "$fish_line" >> "$fish_conf"
      echo "  Added alias to $fish_conf"
    fi
    added_shells+=("fish")
  fi

  if [[ ${#added_shells[@]} -gt 0 ]]; then
    echo ""
    echo "  Reload your shell to pick up the alias:"
    for shell in "${added_shells[@]}"; do
      case "$shell" in
        zsh)  echo "    zsh:  source ~/.zshrc" ;;
        bash) echo "    bash: source ~/.bashrc" ;;
        fish) echo "    fish: source ~/.config/fish/config.fish" ;;
      esac
    done
  fi
}

install_openspec() {
  echo ""
  echo "Installing OpenSpec CLI..."

  if ! command -v node &>/dev/null; then
    echo "  ⚠ Node.js not found. OpenSpec requires Node.js >= $OPENSPEC_MIN_NODE."
    echo "  Skipping OpenSpec installation. Install Node.js and run:"
    echo "    npm install -g @fission-ai/openspec@latest"
    return
  fi

  local node_version
  node_version="$(node -v | sed 's/^v//')"
  if ! version_gte "$node_version" "$OPENSPEC_MIN_NODE"; then
    echo "  ⚠ Node.js $node_version found, but OpenSpec requires >= $OPENSPEC_MIN_NODE."
    echo "  Skipping OpenSpec installation. Upgrade Node.js and run:"
    echo "    npm install -g @fission-ai/openspec@latest"
    return
  fi

  local pkg_mgr=""
  if command -v bun &>/dev/null; then
    pkg_mgr="bun"
  elif command -v npm &>/dev/null; then
    pkg_mgr="npm"
  else
    echo "  ⚠ Neither bun nor npm found. Install one and run:"
    echo "    npm install -g @fission-ai/openspec@latest"
    echo "    # or"
    echo "    bun install -g @fission-ai/openspec@latest"
    return
  fi

  echo "  Using $pkg_mgr..."
  $pkg_mgr install -g @fission-ai/openspec@latest
  echo "  ✓ OpenSpec CLI installed ($(openspec --version 2>/dev/null || echo 'unknown version'))"
}

make_link() {
  local src="$1"
  local dest="$2"
  # Compute relative path from dest's parent to src
  local rel
  rel="$(python3 -c "import os.path; print(os.path.relpath('$src', os.path.dirname('$dest')))")"
  rm -rf "$dest"
  ln -s "$rel" "$dest"
}

install_solon() {
  local platform="$1"
  local global="$2"
  local target
  local src_dir

  case "$platform" in
    claude)
      src_dir="$SCRIPT_DIR/claude"
      if $global; then
        target="$HOME/.claude"
      else
        target=".claude"
      fi
      mkdir -p "$target/agents" "$target/skills"
      if $global; then
        # Global: symlink so repo changes are picked up immediately
        make_link "$src_dir/agent/solon.md" "$target/agents/solon.md"
        for skill_dir in "$src_dir"/skills/*/; do
          local skill_name
          skill_name=$(basename "$skill_dir")
          make_link "$skill_dir" "$target/skills/$skill_name"
        done
      else
        # Project-local: copy (repo may not be available from other projects)
        cp "$src_dir/agent/solon.md" "$target/agents/solon.md"
        for skill_dir in "$src_dir"/skills/*/; do
          local skill_name
          skill_name=$(basename "$skill_dir")
          mkdir -p "$target/skills/$skill_name"
          cp "$skill_dir"SKILL.md "$target/skills/$skill_name/SKILL.md"
        done
      fi
      echo ""
      if $global; then
        echo "Installed Solon for Claude Code ($target/) via symlinks:"
      else
        echo "Installed Solon for Claude Code ($target/):"
      fi
      echo "  $target/agents/solon.md"
      for skill_dir in "$src_dir"/skills/*/; do
        echo "  $target/skills/$(basename "$skill_dir")/SKILL.md"
      done
      if $global; then
        echo ""
        echo "Shell alias:"
        install_alias
      fi
      ;;
    opencode)
      src_dir="$SCRIPT_DIR/opencode"
      if $global; then
        target="$HOME/.config/opencode"
      else
        target=".opencode"
      fi
      mkdir -p "$target/agents" "$target/skills"
      if $global; then
        make_link "$src_dir/agent/solon.md" "$target/agents/solon.md"
        for skill_dir in "$src_dir"/skills/*/; do
          local skill_name
          skill_name=$(basename "$skill_dir")
          make_link "$skill_dir" "$target/skills/$skill_name"
        done
      else
        cp "$src_dir/agent/solon.md" "$target/agents/solon.md"
        for skill_dir in "$src_dir"/skills/*/; do
          local skill_name
          skill_name=$(basename "$skill_dir")
          mkdir -p "$target/skills/$skill_name"
          cp "$skill_dir"SKILL.md "$target/skills/$skill_name/SKILL.md"
        done
      fi
      echo ""
      if $global; then
        echo "Installed Solon for OpenCode ($target/) via symlinks:"
      else
        echo "Installed Solon for OpenCode ($target/):"
      fi
      echo "  $target/agents/solon.md"
      echo "  $target/skills/ ($(ls -d "$src_dir"/skills/*/ | wc -l) skills)"
      ;;
  esac
}

# ── Non-interactive mode (backwards-compatible) ─────────────────────

if [[ $# -gt 0 ]]; then
  PLATFORM=${1:-}
  GLOBAL=false
  SKIP_OPENSPEC=false

  shift || true
  for arg in "$@"; do
    case "$arg" in
      --global) GLOBAL=true ;;
      --skip-openspec) SKIP_OPENSPEC=true ;;
      *) ;;
    esac
  done

  case "$PLATFORM" in
    claude|opencode)
      install_solon "$PLATFORM" "$GLOBAL"
      if ! $SKIP_OPENSPEC; then
        install_openspec
        if ! $GLOBAL; then
          echo ""
          echo "Initializing OpenSpec in current project..."
          openspec init
          echo "  ✓ OpenSpec initialized"
        fi
      fi
      ;;
    *)
      echo "Unknown platform: $PLATFORM"
      echo "Usage: ./install.sh <claude|opencode> [--global] [--skip-openspec]"
      exit 1
      ;;
  esac
  exit 0
fi

# ── Interactive mode ─────────────────────────────────────────────────

echo "Solon — OpenSpec Design Partner"
echo "================================"

# 1) Choose platform
prompt_choice "Which platform are you using?" "Claude Code" "OpenCode"
case $CHOICE in
  0) PLATFORM="claude" ;;
  1) PLATFORM="opencode" ;;
esac

# 2) Choose scope
prompt_choice "Where should Solon be installed?" "Project-local (current directory)" "Global (available in all projects)"
case $CHOICE in
  0) GLOBAL=false ;;
  1) GLOBAL=true ;;
esac

# 3) Install Solon agent + skills
install_solon "$PLATFORM" "$GLOBAL"

# 4) OpenSpec
if command -v openspec &>/dev/null; then
  echo ""
  echo "OpenSpec CLI already installed ($(openspec --version 2>/dev/null || echo 'unknown version'))."
else
  prompt_choice "Install OpenSpec CLI?" "Yes" "No"
  case $CHOICE in
    0)
      install_openspec
      ;;
    1)
      echo ""
      echo "Skipping OpenSpec installation."
      ;;
  esac
fi

if ! $GLOBAL && command -v openspec &>/dev/null && [[ ! -d openspec ]]; then
  echo ""
  echo "Initializing OpenSpec in current project..."
  openspec init
  echo "  ✓ OpenSpec initialized"
fi

echo ""
echo "Done! You're ready to go."
