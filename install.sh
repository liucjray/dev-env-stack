#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stow_dir="${STOW_DIR:-"$repo_root/stow"}"

windows_target="${WINDOWS_TARGET:-}"
wsl_target="${WSL_TARGET:-$HOME}"

if [[ -z "$windows_target" ]]; then
  if command -v powershell.exe >/dev/null 2>&1; then
    windows_target="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("UserProfile")' | tr -d '\r')"
  elif command -v cmd.exe >/dev/null 2>&1; then
    windows_target="$(cmd.exe /c echo %USERPROFILE% | tr -d '\r')"
  fi
fi

if [[ -z "$windows_target" ]]; then
  echo "Could not detect Windows user profile. Set WINDOWS_TARGET manually." >&2
  exit 1
fi

if [[ "$windows_target" =~ ^[A-Za-z]:\\ ]] && command -v wslpath >/dev/null 2>&1; then
  windows_target="$(wslpath "$windows_target")"
fi

if [[ "$windows_target" =~ ^[A-Za-z]:\\ ]]; then
  echo "Windows target must be a WSL path when using stow from WSL. Set WINDOWS_TARGET to something like /mnt/c/Users/<you>." >&2
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "stow is required but was not found in PATH." >&2
  exit 1
fi

backup_existing_file() {
  local path="$1"
  local label="$2"

  if [[ -e "$path" && ! -L "$path" ]]; then
    local backup_path="${path}.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing $label to $backup_path"
    cp -a "$path" "$backup_path"
    mv "$path" "${path}.real"
  fi
}

install_windows_wezterm() {
  local source_path="$repo_root/stow/windows/.wezterm.lua"
  local target_path="$windows_target/.wezterm.lua"

  if [[ -L "$target_path" ]]; then
    local backup_path="${target_path}.link.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing Windows WezTerm symlink to $backup_path"
    mv "$target_path" "$backup_path"
  elif [[ -e "$target_path" ]]; then
    backup_existing_file "$target_path" "Windows WezTerm config"
  fi

  echo "Installing Windows WezTerm config by copy to $target_path"
  cp -f "$source_path" "$target_path"
}

echo "Using stow dir: $stow_dir"
echo "Windows target: $windows_target"
echo "WSL target: $wsl_target"

install_windows_wezterm
backup_existing_file "$wsl_target/.config/starship.toml" "WSL Starship config"
backup_existing_file "$wsl_target/.tmux.conf" "WSL tmux config"

stow -d "$stow_dir" -t "$wsl_target" wsl

echo "Done."
