#!/usr/bin/env bash
# =============================================================================
# Promptor - Powerline Bash Prompt with Async Git Support
# =============================================================================
# A customizable powerline-style bash prompt with async git integration
# and live customization support.
#
# Author: Based on MickaelBlet/Promptor concept, adapted for Bash
# License: MIT
# =============================================================================

# Prevent multiple sourcing
[[ -n "${PROMPTOR_LOADED:-}" ]] && return 0
export PROMPTOR_LOADED=1

# =============================================================================
# CONFIGURATION DEFAULTS
# =============================================================================

# Directories
PROMPTOR_DIR="${PROMPTOR_DIR:-${HOME}/.config/promptor}"
PROMPTOR_CACHE_DIR="${PROMPTOR_CACHE_DIR:-${PROMPTOR_DIR}/cache}"
PROMPTOR_CONFIG_FILE="${PROMPTOR_CONFIG_FILE:-${PROMPTOR_DIR}/promptor.conf}"

# Powerline Characters (Unicode)
declare -gA PROMPTOR_CHARS=(
    [hard_divider]=$'\uE0B0'      #
    [soft_divider]=$'\uE0B1'      #
    [hard_divider_left]=$'\uE0B2' #
    [soft_divider_left]=$'\uE0B3' #
    [branch]=$'\uE0A0'            #
    [readonly]=$'\uE0A2'          #
    [detached]=$'\u27A6'          # ➦
    [tag]=$'\uF412'               #
    [stash]=$'\uF01C'             #
    [ahead]=$'\u2191'             # ↑
    [behind]=$'\u2193'            # ↓
    [staged]=$'\u2714'            # ✔
    [unstaged]=$'\u270E'          # ✎
    [untracked]=$'\u2026'         # …
    [conflict]=$'\u2716'          # ✖
    [clean]=$'\u2714'             # ✔
    [folder]=$'\uF07B'            #
    [home]=$'\uF015'              #
    [user]=$'\uF007'              #
    [host]=$'\uF108'              #
    [root]=$'\u26A1'              # ⚡
    [jobs]=$'\u2699'              # ⚙
    [time]=$'\uF017'              #
    [error]=$'\u2718'             # ✘
    [success]=$'\u2714'           # ✔
    [python]=$'\uE606'            #
    [node]=$'\uE718'              #
    [ssh]=$'\uF489'               #
)

# ASCII fallback characters
declare -gA PROMPTOR_CHARS_ASCII=(
    [hard_divider]='>'
    [soft_divider]='|'
    [hard_divider_left]='<'
    [soft_divider_left]='|'
    [branch]='Y'
    [readonly]='RO'
    [detached]='D'
    [tag]='T'
    [stash]='$'
    [ahead]='^'
    [behind]='v'
    [staged]='+'
    [unstaged]='*'
    [untracked]='?'
    [conflict]='!'
    [clean]='='
    [folder]='/'
    [home]='~'
    [user]='@'
    [host]='#'
    [root]='#'
    [jobs]='&'
    [time]='@'
    [error]='X'
    [success]='V'
    [python]='Py'
    [node]='Njs'
    [ssh]='SSH'
)

# 256 Color Palette (name -> color code)
declare -gA PROMPTOR_COLORS=(
    # Basic colors
    [black]=0      [red]=1        [green]=2      [yellow]=3
    [blue]=4       [magenta]=5    [cyan]=6       [white]=7
    # Bright colors
    [bright_black]=8   [bright_red]=9     [bright_green]=10  [bright_yellow]=11
    [bright_blue]=12   [bright_magenta]=13 [bright_cyan]=14  [bright_white]=15
    # Extended colors (commonly used)
    [orange]=208   [pink]=213     [purple]=129   [teal]=30
    [gray]=240     [light_gray]=250 [dark_gray]=235
    # Solarized
    [sol_base03]=234  [sol_base02]=235  [sol_base01]=240  [sol_base00]=241
    [sol_base0]=244   [sol_base1]=245   [sol_base2]=254   [sol_base3]=230
    [sol_yellow]=136  [sol_orange]=166  [sol_red]=160     [sol_magenta]=125
    [sol_violet]=61   [sol_blue]=33     [sol_cyan]=37     [sol_green]=64
    # Git colors
    [git_clean]=70    [git_dirty]=208   [git_staged]=220  [git_conflict]=160
)

# Default segment colors [bg, fg]
declare -gA PROMPTOR_SEGMENT_COLORS=(
    [user]="27 255"
    [host]="33 255"
    [ssh]="166 255"
    [path]="237 250"
    [path_readonly]="124 255"
    [git_clean]="70 232"
    [git_dirty]="208 232"
    [git_staged]="226 232"
    [git_conflict]="160 255"
    [git_detached]="125 255"
    [virtualenv]="35 255"
    [node_env]="34 232"
    [jobs]="240 255"
    [status_ok]="236 70"
    [status_error]="236 160"
    [time]="238 250"
    [newline]="0 0"
    [root]="160 255"
)

# Default prompt layout
PROMPTOR_LAYOUT="${PROMPTOR_LAYOUT:-user host path git_status newline status}"
PROMPTOR_RPROMPT_LAYOUT="${PROMPTOR_RPROMPT_LAYOUT:-time}"

# Async settings
PROMPTOR_ASYNC_ENABLED="${PROMPTOR_ASYNC_ENABLED:-1}"
PROMPTOR_ASYNC_TIMEOUT="${PROMPTOR_ASYNC_TIMEOUT:-5}"

# Git settings
PROMPTOR_GIT_SHOW_STASH="${PROMPTOR_GIT_SHOW_STASH:-1}"
PROMPTOR_GIT_SHOW_UPSTREAM="${PROMPTOR_GIT_SHOW_UPSTREAM:-1}"
PROMPTOR_GIT_SHOW_COUNTS="${PROMPTOR_GIT_SHOW_COUNTS:-1}"

# Display settings
PROMPTOR_USE_POWERLINE="${PROMPTOR_USE_POWERLINE:-1}"
PROMPTOR_PATH_STYLE="${PROMPTOR_PATH_STYLE:-short}"  # full, short, basename
PROMPTOR_PATH_MAX_DEPTH="${PROMPTOR_PATH_MAX_DEPTH:-3}"
PROMPTOR_SHOW_USER_HOST_ALWAYS="${PROMPTOR_SHOW_USER_HOST_ALWAYS:-0}"

# =============================================================================
# COLOR FUNCTIONS
# =============================================================================

# Get color code from name or number
promptor::color_code() {
    local color="$1"
    if [[ "$color" =~ ^[0-9]+$ ]]; then
        echo "$color"
    elif [[ -n "${PROMPTOR_COLORS[$color]:-}" ]]; then
        echo "${PROMPTOR_COLORS[$color]}"
    else
        echo "0"
    fi
}

# Generate ANSI escape sequence for foreground color
promptor::fg() {
    local code
    code=$(promptor::color_code "$1")
    echo -n "\[\033[38;5;${code}m\]"
}

# Generate ANSI escape sequence for background color
promptor::bg() {
    local code
    code=$(promptor::color_code "$1")
    echo -n "\[\033[48;5;${code}m\]"
}

# Reset all colors
promptor::reset() {
    echo -n "\[\033[0m\]"
}

# =============================================================================
# CHARACTER FUNCTIONS
# =============================================================================

# Get character (powerline or ASCII)
promptor::char() {
    local name="$1"
    if [[ "${PROMPTOR_USE_POWERLINE:-1}" == "1" ]]; then
        echo -n "${PROMPTOR_CHARS[$name]:-}"
    else
        echo -n "${PROMPTOR_CHARS_ASCII[$name]:-}"
    fi
}

# =============================================================================
# SEGMENT RENDERING
# =============================================================================

# Global state for segment rendering
declare -g PROMPTOR_LAST_BG=""
declare -g PROMPTOR_SEGMENTS=""

# Start building prompt
promptor::begin() {
    PROMPTOR_LAST_BG=""
    PROMPTOR_SEGMENTS=""
}

# Add a segment
# Usage: promptor::segment <bg_color> <fg_color> <content>
promptor::segment() {
    local bg="$1"
    local fg="$2"
    local content="$3"

    [[ -z "$content" ]] && return

    local segment=""
    local divider
    divider=$(promptor::char "hard_divider")

    # Add separator from previous segment
    if [[ -n "$PROMPTOR_LAST_BG" ]]; then
        if [[ "$bg" == "$PROMPTOR_LAST_BG" ]]; then
            # Same background, use soft divider
            segment+=$(promptor::fg "250")
            segment+=$(promptor::char "soft_divider")
        else
            # Different background, use hard divider with transition
            segment+=$(promptor::fg "$PROMPTOR_LAST_BG")
            segment+=$(promptor::bg "$bg")
            segment+="$divider"
        fi
    else
        segment+=$(promptor::bg "$bg")
    fi

    # Add content
    segment+=$(promptor::fg "$fg")
    segment+=$(promptor::bg "$bg")
    segment+=" ${content} "

    PROMPTOR_LAST_BG="$bg"
    PROMPTOR_SEGMENTS+="$segment"
}

# End prompt with final divider
promptor::end() {
    local segment=""
    local divider
    divider=$(promptor::char "hard_divider")

    if [[ -n "$PROMPTOR_LAST_BG" ]]; then
        segment+=$(promptor::reset)
        segment+=$(promptor::fg "$PROMPTOR_LAST_BG")
        segment+="$divider"
        segment+=$(promptor::reset)
    fi

    segment+=" "
    PROMPTOR_SEGMENTS+="$segment"
    echo -n "$PROMPTOR_SEGMENTS"
}

# =============================================================================
# BUILT-IN SEGMENTS
# =============================================================================

# User segment
promptor::segment_user() {
    local colors=(${PROMPTOR_SEGMENT_COLORS[user]})
    local bg="${colors[0]}"
    local fg="${colors[1]}"
    local icon
    icon=$(promptor::char "user")

    if [[ $EUID -eq 0 ]]; then
        colors=(${PROMPTOR_SEGMENT_COLORS[root]})
        bg="${colors[0]}"
        fg="${colors[1]}"
        icon=$(promptor::char "root")
    fi

    promptor::segment "$bg" "$fg" "${icon} \\u"
}

# Host segment
promptor::segment_host() {
    local colors=(${PROMPTOR_SEGMENT_COLORS[host]})
    local bg="${colors[0]}"
    local fg="${colors[1]}"

    # Check if in SSH session
    if [[ -n "${SSH_CLIENT:-}${SSH_TTY:-}${SSH_CONNECTION:-}" ]]; then
        colors=(${PROMPTOR_SEGMENT_COLORS[ssh]})
        bg="${colors[0]}"
        fg="${colors[1]}"
        local icon
        icon=$(promptor::char "ssh")
        promptor::segment "$bg" "$fg" "${icon} \\h"
    elif [[ "${PROMPTOR_SHOW_USER_HOST_ALWAYS:-0}" == "1" ]]; then
        local icon
        icon=$(promptor::char "host")
        promptor::segment "$bg" "$fg" "${icon} \\h"
    fi
}

# Path segment
promptor::segment_path() {
    local colors
    local icon

    if [[ ! -w "$PWD" ]]; then
        colors=(${PROMPTOR_SEGMENT_COLORS[path_readonly]})
        icon=$(promptor::char "readonly")
    else
        colors=(${PROMPTOR_SEGMENT_COLORS[path]})
        icon=$(promptor::char "folder")
    fi

    local bg="${colors[0]}"
    local fg="${colors[1]}"
    local path_display

    case "${PROMPTOR_PATH_STYLE:-short}" in
        full)
            path_display="\\w"
            ;;
        basename)
            path_display="\\W"
            ;;
        short|*)
            # Show shortened path with max depth
            path_display=$(promptor::shorten_path "$PWD" "${PROMPTOR_PATH_MAX_DEPTH:-3}")
            ;;
    esac

    promptor::segment "$bg" "$fg" "${icon} ${path_display}"
}

# Shorten path to max depth
promptor::shorten_path() {
    local path="$1"
    local max_depth="${2:-3}"

    # Replace home with ~
    path="${path/#$HOME/\~}"

    # Count depth
    local depth
    depth=$(echo "$path" | tr -cd '/' | wc -c)

    if [[ $depth -le $max_depth ]]; then
        echo "$path"
        return
    fi

    # Shorten intermediate directories
    local IFS='/'
    read -ra parts <<< "$path"
    local result=""
    local count=${#parts[@]}
    local start=$((count - max_depth))

    for ((i=0; i<count; i++)); do
        if [[ $i -eq 0 ]]; then
            result="${parts[i]}"
        elif [[ $i -lt $start ]]; then
            # Shorten to first character
            if [[ -n "${parts[i]}" ]]; then
                if [[ "${parts[i]:0:1}" == "." ]]; then
                    result+="/${parts[i]:0:2}"
                else
                    result+="/${parts[i]:0:1}"
                fi
            fi
        else
            result+="/${parts[i]}"
        fi
    done

    echo "$result"
}

# Git status segment (with async support)
promptor::segment_git_status() {
    local git_info
    git_info=$(promptor::git_get_status)

    [[ -z "$git_info" ]] && return

    local branch state staged unstaged untracked conflicts ahead behind stash
    IFS='|' read -r branch state staged unstaged untracked conflicts ahead behind stash <<< "$git_info"

    # Determine colors based on state
    local colors bg fg
    case "$state" in
        clean)
            colors=(${PROMPTOR_SEGMENT_COLORS[git_clean]})
            ;;
        staged)
            colors=(${PROMPTOR_SEGMENT_COLORS[git_staged]})
            ;;
        conflict)
            colors=(${PROMPTOR_SEGMENT_COLORS[git_conflict]})
            ;;
        detached)
            colors=(${PROMPTOR_SEGMENT_COLORS[git_detached]})
            ;;
        *)
            colors=(${PROMPTOR_SEGMENT_COLORS[git_dirty]})
            ;;
    esac

    bg="${colors[0]}"
    fg="${colors[1]}"

    # Build git status string
    local git_str=""
    local branch_icon

    if [[ "$state" == "detached" ]]; then
        branch_icon=$(promptor::char "detached")
    else
        branch_icon=$(promptor::char "branch")
    fi

    git_str+="${branch_icon} ${branch}"

    # Add upstream info
    if [[ "${PROMPTOR_GIT_SHOW_UPSTREAM:-1}" == "1" ]]; then
        if [[ "$ahead" -gt 0 ]]; then
            git_str+=" $(promptor::char ahead)"
            [[ "${PROMPTOR_GIT_SHOW_COUNTS:-1}" == "1" ]] && git_str+="$ahead"
        fi
        if [[ "$behind" -gt 0 ]]; then
            git_str+=" $(promptor::char behind)"
            [[ "${PROMPTOR_GIT_SHOW_COUNTS:-1}" == "1" ]] && git_str+="$behind"
        fi
    fi

    # Add status indicators
    [[ "$conflicts" -gt 0 ]] && git_str+=" $(promptor::char conflict)$conflicts"
    [[ "$staged" -gt 0 ]] && git_str+=" $(promptor::char staged)$staged"
    [[ "$unstaged" -gt 0 ]] && git_str+=" $(promptor::char unstaged)$unstaged"
    [[ "$untracked" -gt 0 ]] && git_str+=" $(promptor::char untracked)$untracked"

    # Add stash info
    if [[ "${PROMPTOR_GIT_SHOW_STASH:-1}" == "1" && "$stash" -gt 0 ]]; then
        git_str+=" $(promptor::char stash)$stash"
    fi

    promptor::segment "$bg" "$fg" "$git_str"
}

# Virtual environment segment
promptor::segment_virtualenv() {
    [[ -z "${VIRTUAL_ENV:-}" ]] && return

    local colors=(${PROMPTOR_SEGMENT_COLORS[virtualenv]})
    local venv_name
    venv_name=$(basename "$VIRTUAL_ENV")
    local icon
    icon=$(promptor::char "python")

    promptor::segment "${colors[0]}" "${colors[1]}" "${icon} ${venv_name}"
}

# Node environment segment
promptor::segment_node_env() {
    [[ -z "${NODE_ENV:-}" ]] && return

    local colors=(${PROMPTOR_SEGMENT_COLORS[node_env]})
    local icon
    icon=$(promptor::char "node")

    promptor::segment "${colors[0]}" "${colors[1]}" "${icon} ${NODE_ENV}"
}

# Background jobs segment
promptor::segment_jobs() {
    local job_count
    job_count=$(jobs -p 2>/dev/null | wc -l)

    [[ "$job_count" -eq 0 ]] && return

    local colors=(${PROMPTOR_SEGMENT_COLORS[jobs]})
    local icon
    icon=$(promptor::char "jobs")

    promptor::segment "${colors[0]}" "${colors[1]}" "${icon} ${job_count}"
}

# Exit status segment
promptor::segment_status() {
    local last_status="${PROMPTOR_LAST_EXIT_STATUS:-0}"
    local colors icon

    if [[ "$last_status" -eq 0 ]]; then
        colors=(${PROMPTOR_SEGMENT_COLORS[status_ok]})
        icon=$(promptor::char "success")
    else
        colors=(${PROMPTOR_SEGMENT_COLORS[status_error]})
        icon=$(promptor::char "error")
    fi

    promptor::segment "${colors[0]}" "${colors[1]}" "${icon}"
}

# Time segment
promptor::segment_time() {
    local colors=(${PROMPTOR_SEGMENT_COLORS[time]})
    local icon
    icon=$(promptor::char "time")

    promptor::segment "${colors[0]}" "${colors[1]}" "${icon} \\t"
}

# Newline segment (for multi-line prompts)
promptor::segment_newline() {
    if [[ -n "$PROMPTOR_LAST_BG" ]]; then
        PROMPTOR_SEGMENTS+=$(promptor::reset)
        PROMPTOR_SEGMENTS+=$(promptor::fg "$PROMPTOR_LAST_BG")
        PROMPTOR_SEGMENTS+=$(promptor::char "hard_divider")
        PROMPTOR_SEGMENTS+=$(promptor::reset)
        PROMPTOR_SEGMENTS+="\n"
        PROMPTOR_LAST_BG=""
    fi
}

# =============================================================================
# GIT FUNCTIONS
# =============================================================================

# Async git status file
PROMPTOR_GIT_ASYNC_FILE="${PROMPTOR_CACHE_DIR}/git_status_$$"
PROMPTOR_GIT_ASYNC_PID=""
PROMPTOR_GIT_ASYNC_PENDING=""
PROMPTOR_PARENT_PID=$$

# Get git status (sync or from async cache)
promptor::git_get_status() {
    # Check if we're in a git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        return
    fi

    if [[ "${PROMPTOR_ASYNC_ENABLED:-1}" == "1" ]]; then
        # Use async result if available
        if [[ -f "$PROMPTOR_GIT_ASYNC_FILE" ]]; then
            cat "$PROMPTOR_GIT_ASYNC_FILE"
        else
            # Fallback to sync on first run
            promptor::git_status_sync
        fi
    else
        promptor::git_status_sync
    fi
}

# Synchronous git status
promptor::git_status_sync() {
    local branch state staged=0 unstaged=0 untracked=0 conflicts=0 ahead=0 behind=0 stash=0

    # Get branch name
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -z "$branch" ]]; then
        # Detached HEAD
        branch=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        state="detached"
    fi

    # Get status counts
    local git_status
    git_status=$(git status --porcelain=v1 2>/dev/null)

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local xy="${line:0:2}"
        local x="${xy:0:1}"
        local y="${xy:1:1}"

        # Conflicts
        if [[ "$x" == "U" || "$y" == "U" || "$xy" == "AA" || "$xy" == "DD" ]]; then
            ((conflicts++))
        else
            # Staged
            [[ "$x" != " " && "$x" != "?" ]] && ((staged++))
            # Unstaged
            [[ "$y" != " " && "$y" != "?" ]] && ((unstaged++))
        fi

        # Untracked
        [[ "$xy" == "??" ]] && ((untracked++))
    done <<< "$git_status"

    # Get upstream status
    local upstream
    upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        local counts
        counts=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        if [[ -n "$counts" ]]; then
            ahead=$(echo "$counts" | cut -f1)
            behind=$(echo "$counts" | cut -f2)
        fi
    fi

    # Get stash count
    stash=$(git stash list 2>/dev/null | wc -l)

    # Determine state if not already set
    if [[ -z "$state" ]]; then
        if [[ $conflicts -gt 0 ]]; then
            state="conflict"
        elif [[ $staged -gt 0 && $unstaged -eq 0 && $untracked -eq 0 ]]; then
            state="staged"
        elif [[ $staged -eq 0 && $unstaged -eq 0 && $untracked -eq 0 ]]; then
            state="clean"
        else
            state="dirty"
        fi
    fi

    echo "${branch}|${state}|${staged}|${unstaged}|${untracked}|${conflicts}|${ahead}|${behind}|${stash}"
}

# Start async git status worker
promptor::git_async_start() {
    [[ "${PROMPTOR_ASYNC_ENABLED:-1}" != "1" ]] && return

    # Check if we're in a git repo first
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        rm -f "$PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null
        return
    fi

    # Kill previous worker if running
    if [[ -n "$PROMPTOR_GIT_ASYNC_PID" ]] && kill -0 "$PROMPTOR_GIT_ASYNC_PID" 2>/dev/null; then
        kill "$PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
    fi

    # Store current git info hash to detect changes
    local old_info=""
    [[ -f "$PROMPTOR_GIT_ASYNC_FILE" ]] && old_info=$(cat "$PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null)

    # Mark as pending update
    PROMPTOR_GIT_ASYNC_PENDING=1

    # Start new worker that signals parent when done
    (
        local result
        result=$(promptor::git_status_sync 2>/dev/null)
        echo "$result" > "$PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null

        # Only signal if the result changed
        if [[ "$result" != "$old_info" ]]; then
            # Signal parent to redraw prompt
            kill -USR1 "$PROMPTOR_PARENT_PID" 2>/dev/null
        fi
    ) &
    PROMPTOR_GIT_ASYNC_PID=$!
    disown "$PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
}

# Cleanup async files
promptor::git_async_cleanup() {
    rm -f "${PROMPTOR_CACHE_DIR}/git_status_"* 2>/dev/null
}

# =============================================================================
# ASYNC PROMPT REDRAW
# =============================================================================

# Expand PS1 prompt string (compatible with bash 4.0+)
promptor::expand_prompt() {
    local prompt="$1"
    # Use bash's internal prompt expansion if available (4.4+)
    if [[ "${BASH_VERSINFO[0]}" -ge 5 ]] || \
       [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 ]]; then
        printf '%s' "${prompt@P}"
    else
        # Fallback: basic expansion for older bash
        # This handles common escape sequences
        local expanded="$prompt"
        expanded="${expanded//\\u/$USER}"
        expanded="${expanded//\\h/${HOSTNAME%%.*}}"
        expanded="${expanded//\\H/$HOSTNAME}"
        expanded="${expanded//\\w/$PWD}"
        expanded="${expanded//\\W/${PWD##*/}}"
        expanded="${expanded//\\t/$(date +%H:%M:%S)}"
        expanded="${expanded//\\d/$(date '+%a %b %d')}"
        expanded="${expanded//\\$/\$}"
        # Remove \[ and \] markers used for non-printing characters
        expanded="${expanded//\\[/}"
        expanded="${expanded//\\]/}"
        printf '%s' "$expanded"
    fi
}

# Redraw the prompt (called when async git completes)
promptor::redraw_prompt() {
    # Only redraw if we have a pending async update
    [[ "${PROMPTOR_GIT_ASYNC_PENDING:-}" != "1" ]] && return
    PROMPTOR_GIT_ASYNC_PENDING=""

    # Build new prompt
    local new_prompt
    new_prompt=$(promptor::build_prompt)

    # Check if git info actually changed
    local old_ps1="$PS1"
    PS1="$new_prompt"
    [[ "$old_ps1" == "$PS1" ]] && return

    # Redraw the current line
    # Method: Clear line, reprint prompt, restore user input
    local saved_line="${READLINE_LINE:-}"
    local saved_point="${READLINE_POINT:-0}"

    # Move to column 0, clear to end of screen (handles multiline prompts)
    printf '\r'

    # Calculate lines to clear (for multiline prompts)
    local prompt_lines
    prompt_lines=$(promptor::expand_prompt "$old_ps1" | grep -c $'\n' || echo 0)
    prompt_lines=$((prompt_lines + 1))

    # Move up and clear each line if multiline
    if [[ $prompt_lines -gt 1 ]]; then
        for ((i=1; i<prompt_lines; i++)); do
            printf '\033[A'  # Move up
        done
    fi

    # Clear from cursor to end of screen
    printf '\033[J'

    # Print expanded new prompt
    promptor::expand_prompt "$PS1"

    # Restore user's input
    printf '%s' "$saved_line"

    # Move cursor back to saved position if needed
    local line_len=${#saved_line}
    if [[ $saved_point -lt $line_len ]]; then
        local move_back=$((line_len - saved_point))
        printf '\033[%dD' "$move_back"
    fi
}

# Signal handler for SIGUSR1 (async completion)
promptor::handle_async_signal() {
    # Check if we're at a prompt (not running a command)
    # READLINE_LINE is only set when readline is active
    if [[ -n "${READLINE_LINE+x}" ]] || [[ -z "${PROMPTOR_COMMAND_RUNNING:-}" ]]; then
        promptor::redraw_prompt
    fi
}

# Mark when a command starts/ends (for signal safety)
promptor::preexec() {
    # Only mark as running if this isn't part of PROMPT_COMMAND
    # BASH_COMMAND contains the command being executed
    case "${BASH_COMMAND:-}" in
        *promptor::prompt_command*|*promptor::*) return ;;
    esac
    PROMPTOR_COMMAND_RUNNING=1
}

promptor::precmd() {
    unset PROMPTOR_COMMAND_RUNNING
}

# =============================================================================
# PROMPT BUILDING
# =============================================================================

# Build prompt from layout
promptor::build_prompt() {
    promptor::begin

    local segment
    for segment in $PROMPTOR_LAYOUT; do
        case "$segment" in
            user)       promptor::segment_user ;;
            host)       promptor::segment_host ;;
            path)       promptor::segment_path ;;
            git|git_status) promptor::segment_git_status ;;
            virtualenv) promptor::segment_virtualenv ;;
            node_env)   promptor::segment_node_env ;;
            jobs)       promptor::segment_jobs ;;
            status)     promptor::segment_status ;;
            time)       promptor::segment_time ;;
            newline)    promptor::segment_newline ;;
            *)
                # Check for custom segment function
                if declare -f "promptor::segment_${segment}" &>/dev/null; then
                    "promptor::segment_${segment}"
                fi
                ;;
        esac
    done

    promptor::end
}

# Build right prompt (for future use)
promptor::build_rprompt() {
    # Note: Bash doesn't natively support right prompt like ZSH
    # This can be used with RPROMPT simulation if desired
    :
}

# =============================================================================
# PROMPT COMMAND
# =============================================================================

# Main prompt command hook
promptor::prompt_command() {
    # Capture exit status FIRST
    PROMPTOR_LAST_EXIT_STATUS=$?

    # Mark that we're at a prompt (not running a command)
    promptor::precmd

    # Start async git worker for next prompt
    promptor::git_async_start

    # Build prompt
    PS1=$(promptor::build_prompt)
}

# =============================================================================
# CONFIGURATION
# =============================================================================

# Load configuration file
promptor::load_config() {
    [[ -f "$PROMPTOR_CONFIG_FILE" ]] && source "$PROMPTOR_CONFIG_FILE"
}

# Save current configuration
promptor::save_config() {
    mkdir -p "$(dirname "$PROMPTOR_CONFIG_FILE")"
    cat > "$PROMPTOR_CONFIG_FILE" << 'CONF'
# Promptor Configuration File
# Edit this file to customize your prompt

# Layout (space-separated segment names)
# Available: user host path git_status virtualenv node_env jobs status time newline
PROMPTOR_LAYOUT="user host path git_status newline status"

# Display settings
PROMPTOR_USE_POWERLINE=1
PROMPTOR_PATH_STYLE="short"    # full, short, basename
PROMPTOR_PATH_MAX_DEPTH=3
PROMPTOR_SHOW_USER_HOST_ALWAYS=0

# Git settings
PROMPTOR_ASYNC_ENABLED=1
PROMPTOR_GIT_SHOW_STASH=1
PROMPTOR_GIT_SHOW_UPSTREAM=1
PROMPTOR_GIT_SHOW_COUNTS=1

# Custom segment colors [bg fg]
# Uncomment and modify to customize
# PROMPTOR_SEGMENT_COLORS[user]="27 255"
# PROMPTOR_SEGMENT_COLORS[host]="33 255"
# PROMPTOR_SEGMENT_COLORS[path]="237 250"
# PROMPTOR_SEGMENT_COLORS[git_clean]="70 232"
# PROMPTOR_SEGMENT_COLORS[git_dirty]="208 232"
# PROMPTOR_SEGMENT_COLORS[status_ok]="236 70"
# PROMPTOR_SEGMENT_COLORS[status_error]="236 160"
CONF
    echo "Configuration saved to: $PROMPTOR_CONFIG_FILE"
}

# =============================================================================
# LIVE CUSTOMIZATION INTERFACE
# =============================================================================

# Interactive customization menu
promptor::customize() {
    local choice
    while true; do
        echo ""
        echo "╔══════════════════════════════════════════╗"
        echo "║       Promptor Live Customization        ║"
        echo "╠══════════════════════════════════════════╣"
        echo "║  1. Change layout                        ║"
        echo "║  2. Toggle powerline/ASCII               ║"
        echo "║  3. Change path style                    ║"
        echo "║  4. Change segment colors                ║"
        echo "║  5. Toggle git options                   ║"
        echo "║  6. Preview current prompt               ║"
        echo "║  7. Save configuration                   ║"
        echo "║  8. Reset to defaults                    ║"
        echo "║  0. Exit                                 ║"
        echo "╚══════════════════════════════════════════╝"
        echo ""
        read -rp "Choice: " choice

        case "$choice" in
            1) promptor::customize_layout ;;
            2) promptor::customize_toggle_powerline ;;
            3) promptor::customize_path_style ;;
            4) promptor::customize_colors ;;
            5) promptor::customize_git ;;
            6) promptor::preview ;;
            7) promptor::save_config ;;
            8) promptor::reset_defaults ;;
            0|q|Q) break ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

# Customize layout
promptor::customize_layout() {
    echo ""
    echo "Current layout: $PROMPTOR_LAYOUT"
    echo ""
    echo "Available segments:"
    echo "  user host path git_status virtualenv node_env jobs status time newline"
    echo ""
    echo "Enter new layout (space-separated) or press Enter to keep current:"
    read -rp "> " new_layout

    if [[ -n "$new_layout" ]]; then
        PROMPTOR_LAYOUT="$new_layout"
        echo "Layout updated!"
    fi
}

# Toggle powerline characters
promptor::customize_toggle_powerline() {
    if [[ "$PROMPTOR_USE_POWERLINE" == "1" ]]; then
        PROMPTOR_USE_POWERLINE=0
        echo "Switched to ASCII mode"
    else
        PROMPTOR_USE_POWERLINE=1
        echo "Switched to Powerline mode"
    fi
}

# Customize path style
promptor::customize_path_style() {
    echo ""
    echo "Current path style: $PROMPTOR_PATH_STYLE"
    echo ""
    echo "Available styles:"
    echo "  1. full     - Show full path"
    echo "  2. short    - Shorten intermediate directories"
    echo "  3. basename - Show only current directory"
    echo ""
    read -rp "Choice [1-3]: " choice

    case "$choice" in
        1) PROMPTOR_PATH_STYLE="full" ;;
        2) PROMPTOR_PATH_STYLE="short" ;;
        3) PROMPTOR_PATH_STYLE="basename" ;;
    esac

    echo "Path style set to: $PROMPTOR_PATH_STYLE"
}

# Customize segment colors
promptor::customize_colors() {
    echo ""
    echo "Available segments to customize:"
    echo "  1. user          6. git_dirty"
    echo "  2. host          7. git_staged"
    echo "  3. path          8. status_ok"
    echo "  4. path_readonly 9. status_error"
    echo "  5. git_clean     0. Back"
    echo ""
    read -rp "Choose segment [0-9]: " seg_choice

    local segment_name=""
    case "$seg_choice" in
        1) segment_name="user" ;;
        2) segment_name="host" ;;
        3) segment_name="path" ;;
        4) segment_name="path_readonly" ;;
        5) segment_name="git_clean" ;;
        6) segment_name="git_dirty" ;;
        7) segment_name="git_staged" ;;
        8) segment_name="status_ok" ;;
        9) segment_name="status_error" ;;
        0|*) return ;;
    esac

    local current_colors=(${PROMPTOR_SEGMENT_COLORS[$segment_name]})
    echo ""
    echo "Current colors for '$segment_name': bg=${current_colors[0]}, fg=${current_colors[1]}"
    echo "Enter color code (0-255) or color name"
    echo ""
    read -rp "Background color: " new_bg
    read -rp "Foreground color: " new_fg

    if [[ -n "$new_bg" && -n "$new_fg" ]]; then
        PROMPTOR_SEGMENT_COLORS[$segment_name]="$new_bg $new_fg"
        echo "Colors updated for '$segment_name'!"
    fi
}

# Customize git options
promptor::customize_git() {
    echo ""
    echo "Git Options:"
    echo "  1. Async updates: ${PROMPTOR_ASYNC_ENABLED:-1}"
    echo "  2. Show stash:    ${PROMPTOR_GIT_SHOW_STASH:-1}"
    echo "  3. Show upstream: ${PROMPTOR_GIT_SHOW_UPSTREAM:-1}"
    echo "  4. Show counts:   ${PROMPTOR_GIT_SHOW_COUNTS:-1}"
    echo "  0. Back"
    echo ""
    read -rp "Toggle option [1-4]: " choice

    case "$choice" in
        1) PROMPTOR_ASYNC_ENABLED=$((1 - ${PROMPTOR_ASYNC_ENABLED:-1})) ;;
        2) PROMPTOR_GIT_SHOW_STASH=$((1 - ${PROMPTOR_GIT_SHOW_STASH:-1})) ;;
        3) PROMPTOR_GIT_SHOW_UPSTREAM=$((1 - ${PROMPTOR_GIT_SHOW_UPSTREAM:-1})) ;;
        4) PROMPTOR_GIT_SHOW_COUNTS=$((1 - ${PROMPTOR_GIT_SHOW_COUNTS:-1})) ;;
    esac
}

# Preview current prompt
promptor::preview() {
    echo ""
    echo "Current prompt preview:"
    echo "─────────────────────────────────────────"
    local preview
    preview=$(promptor::build_prompt)
    echo -e "$preview"
    echo "─────────────────────────────────────────"
}

# Reset to defaults
promptor::reset_defaults() {
    PROMPTOR_LAYOUT="user host path git_status newline status"
    PROMPTOR_USE_POWERLINE=1
    PROMPTOR_PATH_STYLE="short"
    PROMPTOR_PATH_MAX_DEPTH=3
    PROMPTOR_ASYNC_ENABLED=1
    PROMPTOR_GIT_SHOW_STASH=1
    PROMPTOR_GIT_SHOW_UPSTREAM=1
    PROMPTOR_GIT_SHOW_COUNTS=1

    # Reset colors
    PROMPTOR_SEGMENT_COLORS=(
        [user]="27 255"
        [host]="33 255"
        [ssh]="166 255"
        [path]="237 250"
        [path_readonly]="124 255"
        [git_clean]="70 232"
        [git_dirty]="208 232"
        [git_staged]="226 232"
        [git_conflict]="160 255"
        [git_detached]="125 255"
        [virtualenv]="35 255"
        [node_env]="34 232"
        [jobs]="240 255"
        [status_ok]="236 70"
        [status_error]="236 160"
        [time]="238 250"
        [newline]="0 0"
        [root]="160 255"
    )

    echo "Configuration reset to defaults!"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Show help
promptor::help() {
    cat << 'HELP'
Promptor - Powerline Bash Prompt

USAGE:
    source promptor.bash

COMMANDS:
    promptor::customize     Open live customization menu
    promptor::save_config   Save current configuration
    promptor::load_config   Reload configuration file
    promptor::preview       Preview current prompt
    promptor::help          Show this help

CONFIGURATION:
    Edit ~/.config/promptor/promptor.conf or use promptor::customize

LAYOUT SEGMENTS:
    user        Username (with root indicator)
    host        Hostname (highlighted when SSH)
    path        Current directory
    git_status  Git branch and status
    virtualenv  Python virtual environment
    node_env    Node.js environment
    jobs        Background jobs count
    status      Last command exit status
    time        Current time
    newline     Line break for multi-line prompt

ENVIRONMENT VARIABLES:
    PROMPTOR_DIR           Config directory (~/.config/promptor)
    PROMPTOR_LAYOUT        Prompt segments layout
    PROMPTOR_USE_POWERLINE Use powerline glyphs (0/1)
    PROMPTOR_PATH_STYLE    Path display style (full/short/basename)
    PROMPTOR_ASYNC_ENABLED Enable async git (0/1)

For more information, see the README.
HELP
}

# =============================================================================
# INITIALIZATION
# =============================================================================

promptor::init() {
    # Create directories
    mkdir -p "$PROMPTOR_CACHE_DIR"

    # Load configuration
    promptor::load_config

    # Cleanup old async files
    promptor::git_async_cleanup

    # Set up prompt command
    if [[ -z "${PROMPT_COMMAND:-}" ]]; then
        PROMPT_COMMAND="promptor::prompt_command"
    elif [[ "$PROMPT_COMMAND" != *"promptor::prompt_command"* ]]; then
        PROMPT_COMMAND="promptor::prompt_command; ${PROMPT_COMMAND}"
    fi

    # Set up async signal handler for prompt redraw
    # SIGUSR1 is sent by async worker when git status completes
    trap 'promptor::handle_async_signal' USR1

    # Set up DEBUG trap for preexec (marks when command starts)
    # This helps avoid redrawing prompt while a command is running
    if [[ -z "${PROMPTOR_DEBUG_TRAP_SET:-}" ]]; then
        PROMPTOR_DEBUG_TRAP_SET=1
        trap 'promptor::preexec' DEBUG
    fi

    # Trap cleanup on exit
    trap 'promptor::git_async_cleanup' EXIT

    echo "Promptor loaded! Run 'promptor::customize' for live customization."
}

# Initialize if not being sourced for functions only
if [[ "${PROMPTOR_INIT:-1}" == "1" ]]; then
    promptor::init
fi
