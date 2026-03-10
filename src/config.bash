#!/usr/bin/env bash
#
# bash_promptor - Configuration
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#

# Configuration associative array
declare -gA bash_promptor_config

# --- Default Configuration ---

# Powerline mode
bash_promptor_config[powerline]=true

# Prompt layout: space-separated list of segment names
# Available segments: exit_code, user, host, path, git_async
# Each segment can also be a raw definition: "bg fg content"
bash_promptor_config[prompt]="exit_code user host path git_async"

# Glyph style for section separators
# Available: left_hard_divider, left_soft_divider, left_half_circle_thick,
#            left_flame_thick, left_ice_waveform, left_honeycomb,
#            left_lego_separator, left_lego_separator_thin, left_pixel_squares
bash_promptor_config[prompt.glyph]="left_hard_divider"

# Prompt end character
bash_promptor_config[prompt.end]="\$"
bash_promptor_config[prompt.end.root]="#"
bash_promptor_config[prompt.end.bg]=""
bash_promptor_config[prompt.end.fg]="231"

# Title
bash_promptor_config[title]=true
bash_promptor_config[title.max_size]=30

# --- Segment: exit_code ---
bash_promptor_config[exit_code.bg]=125
bash_promptor_config[exit_code.fg]=231

# --- Segment: user ---
bash_promptor_config[user.bg]=240
bash_promptor_config[user.fg]=231
bash_promptor_config[user.root.bg]=124
bash_promptor_config[user.root.fg]=231
bash_promptor_config[user.show]=true

# --- Segment: host ---
bash_promptor_config[host.bg]=238
bash_promptor_config[host.fg]=231
bash_promptor_config[host.show]=true

# --- Segment: path ---
bash_promptor_config[path.bg]=31
bash_promptor_config[path.fg]=231
bash_promptor_config[path.style]="short"  # full, short, basename

# --- Segment: git ---
bash_promptor_config[git]=true
bash_promptor_config[git.color.bg]=240
bash_promptor_config[git.color.fg]=231
bash_promptor_config[git.color.conflict.bg]=124
bash_promptor_config[git.color.conflict.fg]=231
bash_promptor_config[git.color.dirty.bg]=226
bash_promptor_config[git.color.dirty.fg]=232
bash_promptor_config[git.color.added.bg]=207
bash_promptor_config[git.color.added.fg]=232
bash_promptor_config[git.color.untracked.bg]=214
bash_promptor_config[git.color.untracked.fg]=232
bash_promptor_config[git.color.detached.bg]=97
bash_promptor_config[git.color.detached.fg]=231
bash_promptor_config[git.color.remote.bg]=118
bash_promptor_config[git.color.remote.fg]=232
# Priority order for background color selection
bash_promptor_config[git.color.sequence]="conflict dirty added untracked detached remote"
# Which information to display and in what order
bash_promptor_config[git.information.sequence]="dirty added untracked stash upstream"
# Git describe style for detached HEAD: contains, branch, tag, describe
bash_promptor_config[git.describe.style]="tag"
bash_promptor_config[git.hide_if_pwd_ignored]=false
# Characters
bash_promptor_config[git.character.dirty]="M"
bash_promptor_config[git.character.added]="A"
bash_promptor_config[git.character.untracked]="U"
bash_promptor_config[git.character.stash]="S"
bash_promptor_config[git.character.upstream.left]=$'\u2b63'
bash_promptor_config[git.character.upstream.right]=$'\u2b61'
bash_promptor_config[git.character.branch]=$'\ue0a0'
bash_promptor_config[git.character.tag]=$'\uf02b'
bash_promptor_config[git.character.hash]=$'\u2d4c'
bash_promptor_config[git.character.separator]=$'\u2502'
bash_promptor_config[git.character.separator.prompt]=$'\ue0b1'

# --- Segment: git_async ---
bash_promptor_config[git.async.wait.bg]=238
bash_promptor_config[git.async.wait.fg]=231
bash_promptor_config[git.async.wait.character]=$'\uf250'

# Load configuration from a file (key=value format)
__bash_promptor_load_config() {
    local config_file="$1"
    local line key value

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            # Trim whitespace
            key="${key#"${key%%[![:space:]]*}"}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            # Remove surrounding quotes
            if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi
            bash_promptor_config["$key"]="$value"
        fi
    done < "$config_file"
}

# Display current configuration
bash_promptor_config_list() {
    local key
    local -a keys=()
    for key in "${!bash_promptor_config[@]}"; do
        keys+=("$key")
    done
    IFS=$'\n' keys=($(sort <<<"${keys[*]}")); unset IFS

    for key in "${keys[@]}"; do
        printf "  \033[1m%-40s\033[0m = %s\n" "$key" "${bash_promptor_config[$key]}"
    done
}
