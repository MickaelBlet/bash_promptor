#!/usr/bin/env bash
#
# bash_promptor - A Powerline prompt for Bash
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#
# Inspired by MickaelBlet/Promptor (zsh version)
#
# Usage:
#   source /path/to/bash_promptor.bash
#

# Requires bash 4+ for associative arrays
if ((BASH_VERSINFO[0] < 4)); then
    echo "bash_promptor: requires bash 4.0 or later" >&2
    return 1 2>/dev/null || exit 1
fi

# Resolve the directory of this script
__BASH_PROMPTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __BASH_PROMPTOR_DIR

# Source modules
source "${__BASH_PROMPTOR_DIR}/src/config.bash"
source "${__BASH_PROMPTOR_DIR}/src/glyphs.bash"
source "${__BASH_PROMPTOR_DIR}/src/colors.bash"
source "${__BASH_PROMPTOR_DIR}/src/segments.bash"
source "${__BASH_PROMPTOR_DIR}/src/git.bash"
source "${__BASH_PROMPTOR_DIR}/src/prompt.bash"

# Load user configuration if it exists
__bash_promptor_conf="${__BASH_PROMPTOR_DIR}/bash_promptor.conf"
if [[ -f "$__bash_promptor_conf" ]]; then
    __bash_promptor_load_config "$__bash_promptor_conf"
fi
unset __bash_promptor_conf

# Initialize async git worker
__bash_promptor_git_async_init

# --- Async prompt refresh via SIGUSR1 ---
# When the background git worker finishes, it sends SIGUSR1 to this shell.
# The trap handler rebuilds PS1 and forces readline to redraw the prompt.

# Bind the DSR response sequence to redraw once at init time.
# Setting it inside the signal handler is unreliable and can leak ^[[0n.
bind '"\e[0n": redraw-current-line' 2>/dev/null

__BASH_PROMPTOR_GIT_ASYNC_REFRESHING=""

__bash_promptor_async_refresh() {
    # Guard flag prevents __bash_promptor_segment_git_async from launching
    # a new worker during this rebuild (which would cause an infinite loop).
    __BASH_PROMPTOR_GIT_ASYNC_REFRESHING=true
    __bash_promptor_build_prompt
    __BASH_PROMPTOR_GIT_ASYNC_REFRESHING=""
    # Inject a DSR query; the terminal responds with \e[0n which triggers
    # the readline redraw-current-line binding set up above.
    printf '\e[5n' >/dev/tty 2>/dev/null
}
trap '__bash_promptor_async_refresh' SIGUSR1

# Set PROMPT_COMMAND
__bash_promptor_original_prompt_command="${PROMPT_COMMAND:-}"

__bash_promptor_prompt_command() {
    # Capture exit code FIRST before anything else
    local last_exit=$?
    export __BASH_PROMPTOR_LAST_EXIT=$last_exit

    # Build and set the prompt
    __bash_promptor_build_prompt

    # Run original PROMPT_COMMAND if any
    if [[ -n "$__bash_promptor_original_prompt_command" ]]; then
        eval "$__bash_promptor_original_prompt_command"
    fi
}

PROMPT_COMMAND="__bash_promptor_prompt_command"

# Reload function
bash_promptor_reload() {
    local conf="${__BASH_PROMPTOR_DIR}/bash_promptor.conf"
    if [[ -f "$conf" ]]; then
        echo "Reload $conf"
        __bash_promptor_load_config "$conf"
    fi
    source "${__BASH_PROMPTOR_DIR}/bash_promptor.bash"
}
