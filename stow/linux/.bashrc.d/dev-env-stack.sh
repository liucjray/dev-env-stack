# WezTerm prompt helpers for Linux guest VMs (VirtualBuddy).
# Adapted from the wsl package: no WSL_DISTRO_NAME, and the title carries the
# hostname so several agent VMs are told apart at a glance in the tab bar.

__wezterm_update_title() {
    local title="${PWD##*/}"
    [ -z "$title" ] && title="/"
    printf '\033]0;%s:%s\033\\' "${HOSTNAME:-vm}" "$title"
}

__wezterm_update_cwd() {
    local cwd="${PWD// /%20}"
    printf '\033]7;file://%s%s\033\\' "${HOSTNAME:-localhost}" "$cwd"
}

PROMPT_COMMAND="__wezterm_update_title; __wezterm_update_cwd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

if command -v vivid &>/dev/null; then
    export LS_COLORS="$(vivid generate one-dark)"
fi

if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

export PATH="$HOME/.local/bin:$PATH"

alias cx0='codex --dangerously-skip-permissions'
alias cl0='claude --dangerously-skip-permissions'
