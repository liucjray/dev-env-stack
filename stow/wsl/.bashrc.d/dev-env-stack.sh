# WezTerm prompt helpers for WSL bash.

__wezterm_update_title() {
    local title
    if [ -n "$WSL_DISTRO_NAME" ]; then
        title="${PWD##*/}"
        [ -z "$title" ] && title="WSL"
    else
        title="BASH"
    fi
    printf '\033]0;%s\033\\' "$title"
}

__wezterm_update_cwd() {
    local cwd="${PWD// /%20}"
    printf '\033]7;file://%s%s\033\\' "${HOSTNAME:-localhost}" "$cwd"
}

PROMPT_COMMAND="__wezterm_update_title; __wezterm_update_cwd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

if command -v vivid &>/dev/null; then
    export LS_COLORS="$(vivid generate one-dark)"
fi

