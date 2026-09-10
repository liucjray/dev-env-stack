#!/usr/bin/env bash
# Strip per-machine identity from a golden image, in the guest, right before
# the final shutdown.
#
#   curl -fsSL https://raw.githubusercontent.com/liucjray/dev-env-stack/main/vm/seal-golden.sh | bash
#
# vb-clone gives each clone a fresh UUID and MAC on the host side, but anything
# baked into the disk is copied verbatim. Two of those matter:
#
#   /etc/machine-id     systemd-networkd derives the DHCP client identifier
#                       from it, so clones sharing one can be handed the same
#                       lease despite having distinct MACs.
#   /etc/ssh/ssh_host_* every clone would answer with the same host key.
#
# Both are regenerated on next boot, so the golden image must not be booted
# again after this runs — boot a clone instead.

set -euo pipefail

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This seals the Linux guest, not the macOS host." >&2
  exit 1
fi

log "Clearing machine-id"
sudo truncate -s 0 /etc/machine-id
# dbus keeps its own copy; a symlink lets systemd regenerate both at once.
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

log "Removing SSH host keys"
sudo rm -f /etc/ssh/ssh_host_*
# Ubuntu's openssh-server runs `ssh-keygen -A` before sshd when keys are
# missing. Make it explicit so a clone is never left without sshd.
sudo systemctl enable ssh-keygen.service 2>/dev/null || true

log "Resetting cloud-init"
sudo cloud-init clean --logs 2>/dev/null || echo "  (cloud-init not present — fine)"

log "Clearing logs and caches"
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo journalctl --rotate 2>/dev/null || true
sudo journalctl --vacuum-time=1s 2>/dev/null || true
sudo find /var/log -type f -name '*.log' -exec truncate -s 0 {} + 2>/dev/null || true
rm -f "$HOME/.bash_history"

# The golden image's own leases would otherwise be replayed by every clone.
sudo rm -f /var/lib/dhcp/* 2>/dev/null || true

log "Sealed."
cat <<'SUMMARY'

Shut down now and do not boot this VM again:

  sudo shutdown -h now

Every clone regenerates its machine-id and host keys on first boot. That means
ssh will report a changed host key for a name you have connected to before:

  ssh-keygen -R <ip>

Then clone from the host:

  vb-clone vm01 agent-a --boot
SUMMARY
