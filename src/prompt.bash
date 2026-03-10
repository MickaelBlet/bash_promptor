#!/usr/bin/env bash
#
# bash_promptor - Prompt Builder
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#
# Assembles the powerline prompt from configured segments.
#

# Map segment names to their functions
declare -gA __bash_promptor_segment_map
__bash_promptor_segment_map[exit_code]="__bash_promptor_segment_exit_code"
__bash_promptor_segment_map[user]="__bash_promptor_segment_user"
__bash_promptor_segment_map[host]="__bash_promptor_segment_host"
__bash_promptor_segment_map[path]="__bash_promptor_segment_path"
__bash_promptor_segment_map[git]="__bash_promptor_segment_git"
__bash_promptor_segment_map[git_async]="__bash_promptor_segment_git_async"

# Build the complete prompt
__bash_promptor_build_prompt() {
    local segments="${bash_promptor_config[prompt]}"
    local glyph_name="${bash_promptor_config[prompt.glyph]}"
    local separator="${__bash_promptor_glyph[$glyph_name]:-$'\ue0b0'}"

    # Collect all segment outputs
    local -a seg_bg=()
    local -a seg_fg=()
    local -a seg_content=()
    local seg_count=0

    local seg_name
    for seg_name in $segments; do
        local func="${__bash_promptor_segment_map[$seg_name]}"
        if [[ -z "$func" ]]; then
            continue
        fi

        local output
        output=$($func)
        if [[ -z "$output" ]]; then
            continue
        fi

        # Parse "bg fg content" - first two words are bg and fg
        local bg fg content
        bg="${output%% *}"
        output="${output#* }"
        fg="${output%% *}"
        content="${output#* }"

        # Trim whitespace
        bg="${bg#"${bg%%[![:space:]]*}"}"
        fg="${fg#"${fg%%[![:space:]]*}"}"
        content="${content#"${content%%[![:space:]]*}"}"

        if [[ -z "$content" ]]; then
            continue
        fi

        seg_bg+=("$bg")
        seg_fg+=("$fg")
        seg_content+=("$content")
        ((seg_count++))
    done

    # Build the PS1 string
    local ps1=""
    local i

    for ((i = 0; i < seg_count; i++)); do
        local bg="${seg_bg[$i]}"
        local fg="${seg_fg[$i]}"
        local content="${seg_content[$i]}"
        local next_bg=""

        if ((i + 1 < seg_count)); then
            next_bg="${seg_bg[$((i + 1))]}"
        fi

        if [[ "${bash_promptor_config[powerline]}" == true ]]; then
            # Powerline mode
            # Background + foreground for content
            ps1+="\[\033[48;5;${bg}m\]\[\033[38;5;${fg}m\] ${content} "

            # Separator: current bg as fg, next bg as bg
            if [[ -n "$next_bg" ]]; then
                ps1+="\[\033[48;5;${next_bg}m\]\[\033[38;5;${bg}m\]${separator}"
            else
                # Last segment: separator with default bg
                ps1+="\[\033[0m\]\[\033[38;5;${bg}m\]${separator}\[\033[0m\]"
            fi
        else
            # Non-powerline mode (simple colored blocks)
            ps1+="\[\033[48;5;${bg}m\]\[\033[38;5;${fg}m\] ${content} "

            if [[ -z "$next_bg" ]]; then
                ps1+="\[\033[0m\]"
            fi
        fi
    done

    # Add prompt end character
    local end_char
    if [[ "$EUID" -eq 0 ]]; then
        end_char="${bash_promptor_config[prompt.end.root]}"
    else
        end_char="${bash_promptor_config[prompt.end]}"
    fi

    local end_fg="${bash_promptor_config[prompt.end.fg]}"
    local end_bg="${bash_promptor_config[prompt.end.bg]}"
    if [[ -n "$end_bg" ]]; then
        ps1+=" \[\033[48;5;${end_bg}m\]\[\033[38;5;${end_fg}m\]${end_char}\[\033[0m\] "
    else
        ps1+=" ${end_char} "
    fi

    # Update terminal title
    if [[ "${bash_promptor_config[title]}" == true ]]; then
        local title_max="${bash_promptor_config[title.max_size]:-30}"
        local title_dir="${PWD/#$HOME/~}"
        if ((${#title_dir} > title_max)); then
            title_dir="...${title_dir: -$((title_max - 3))}"
        fi
        ps1="\[\033]0;${title_dir}\007\]${ps1}"
    fi

    PS1="$ps1"
}
