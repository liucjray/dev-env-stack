#!/usr/bin/env bash
# Provision a fresh Ubuntu ARM64 guest into a VirtualBuddy golden image.
#
# Run this ONCE, inside the base VM, before it is ever cloned. Everything it
# installs is baked into the image, so each clone boots ready to work.
#
#   curl -fsSL https://raw.githubusercontent.com/liucjray/dev-env-stack/main/vm/guest-bootstrap.sh | bash
#
# Re-running is safe: every step checks for its own result first.

set -euo pipefail

repo_url="${DEV_ENV_STACK_REPO:-https://github.com/liucjray/dev-env-stack.git}"
repo_dir="${DEV_ENV_STACK_DIR:-$HOME/me/dev-env-stack}"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script provisions the Linux guest, not the macOS host." >&2
  exit 1
fi

# ── base packages ────────────────────────────────────────────────────────────
# VirtualBuddy's bundled catalog ships the 26.04 initial ISO, not the 26.04.1
# point release, so bring the image current before anything is cloned from it.
log "Updating the base system"
sudo apt-get update -qq
sudo apt-get full-upgrade -y

log "Installing base packages"
sudo apt-get install -y --no-install-recommends \
  build-essential ca-certificates curl git gnupg jq ripgrep stow tmux unzip \
  openssh-server python3 python3-venv

# ── shared folder from the host (virtiofs) ───────────────────────────────────
# VirtualBuddy exposes the host's shared directory under this tag.
log "Configuring VirtualBuddyShared mount"
share_dir="$HOME/Shared"
mkdir -p "$share_dir"
if ! grep -q VirtualBuddyShared /etc/fstab; then
  echo "VirtualBuddyShared $share_dir virtiofs rw,nofail,_netdev 0 0" | sudo tee -a /etc/fstab >/dev/null
fi
sudo mount -a || echo "  (shared folder not attached to this VM yet — safe to ignore)"

# ── ssh ──────────────────────────────────────────────────────────────────────
# Key-only login. Drop the host's public key into the shared folder as
# authorized_key.pub before running, or append it manually afterwards.
log "Enabling SSH"
sudo systemctl enable --now ssh
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [[ -f "$share_dir/authorized_key.pub" ]]; then
  touch "$HOME/.ssh/authorized_keys" && chmod 600 "$HOME/.ssh/authorized_keys"
  grep -qxFf "$share_dir/authorized_key.pub" "$HOME/.ssh/authorized_keys" 2>/dev/null \
    || cat "$share_dir/authorized_key.pub" >> "$HOME/.ssh/authorized_keys"
  echo "  authorized_keys updated from shared folder"
else
  echo "  no authorized_key.pub in $share_dir — add your host key before cloning"
fi

# ── node (codex CLI is distributed on npm) ───────────────────────────────────
if ! command -v node >/dev/null 2>&1; then
  log "Installing Node.js LTS"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
  # let npm -g install without sudo, so agents never need root
  npm config set prefix "$HOME/.local"
fi

# ── toolchain ────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

command -v starship >/dev/null 2>&1 || {
  log "Installing starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
}

command -v uv >/dev/null 2>&1 || {
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

command -v claude >/dev/null 2>&1 || {
  log "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
}

command -v codex >/dev/null 2>&1 || {
  log "Installing codex"
  npm install -g @openai/codex
}

# ── dotfiles ─────────────────────────────────────────────────────────────────
log "Applying dev-env-stack (linux package)"
if [[ -d "$repo_dir/.git" ]]; then
  git -C "$repo_dir" pull --ff-only
else
  mkdir -p "$(dirname "$repo_dir")"
  git clone "$repo_url" "$repo_dir"
fi

# Stow folds a whole directory when the target does not exist, which would make
# ~/.config a symlink into the repo and let every tool write its state there.
# Pre-creating the real directories keeps stow to file-level links.
mkdir -p "$HOME/.config" "$HOME/.bashrc.d" "$HOME/.claude"

stow -d "$repo_dir/stow" -t "$HOME" --restow linux
chmod +x "$HOME/.claude/statusline.sh" 2>/dev/null || true

if ! grep -q 'bashrc.d/dev-env-stack.sh' "$HOME/.bashrc"; then
  echo 'source ~/.bashrc.d/dev-env-stack.sh' >> "$HOME/.bashrc"
fi

# ── done ─────────────────────────────────────────────────────────────────────
log "Done. Golden image ready."
cat <<'SUMMARY'

Before shutting down and cloning this VM:

  1. claude          # sign in — the token is baked into every clone
  2. codex           # sign in
  3. git config --global user.name / user.email
  4. sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*
  5. sudo cloud-init clean --logs 2>/dev/null || true
  6. sudo shutdown -h now

Then never boot this VM again — clone it instead.
SUMMARY
