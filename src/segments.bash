#!/usr/bin/env bash
#
# bash_promptor - Built-in Segments
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#
# Each segment function outputs: "bg fg content" (3 space-separated values)
# If a segment has nothing to display, it outputs nothing.
#

# --- Exit Code Segment ---
__bash_promptor_segment_exit_code() {
    if [[ "$__BASH_PROMPTOR_LAST_EXIT" -ne 0 ]]; then
        echo "${bash_promptor_config[exit_code.bg]}" \
             "${bash_promptor_config[exit_code.fg]}" \
             "${__BASH_PROMPTOR_LAST_EXIT}"
    fi
}

# --- User Segment ---
__bash_promptor_segment_user() {
    if [[ "${bash_promptor_config[user.show]}" != true ]]; then
        return
    fi

    local bg fg
    if [[ "$EUID" -eq 0 ]]; then
        bg="${bash_promptor_config[user.root.bg]}"
        fg="${bash_promptor_config[user.root.fg]}"
    else
        bg="${bash_promptor_config[user.bg]}"
        fg="${bash_promptor_config[user.fg]}"
    fi

    echo "$bg" "$fg" "\\u"
}

# --- Host Segment ---
__bash_promptor_segment_host() {
    if [[ "${bash_promptor_config[host.show]}" != true ]]; then
        return
    fi

    echo "${bash_promptor_config[host.bg]}" \
         "${bash_promptor_config[host.fg]}" \
         "\\h"
}

# --- Path Segment ---
__bash_promptor_segment_path() {
    local bg="${bash_promptor_config[path.bg]}"
    local fg="${bash_promptor_config[path.fg]}"
    local path_content

    case "${bash_promptor_config[path.style]}" in
        full)
            path_content="\\w"
            ;;
        basename)
            path_content="\\W"
            ;;
        short|*)
            path_content="\\w"
            ;;
    esac

    echo "$bg" "$fg" "$path_content"
}
