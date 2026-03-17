#!/usr/bin/env bash
#
# bash_promptor - Git Status (with async support)
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#
# Async strategy:
#   - A background process computes the full git status and writes it to a temp file
#   - On each prompt render, we read the cached result and display it
#   - A new background job is launched to update the cache for next prompt
#   - This prevents any lag in the prompt from slow git operations
#

# Temp file for async git result (per-shell instance)
__BASH_PROMPTOR_GIT_ASYNC_FILE="/tmp/bash_promptor_git_async_$$"
__BASH_PROMPTOR_GIT_ASYNC_PID=""
__BASH_PROMPTOR_GIT_ASYNC_PWD=""

# --- Async Init ---
__bash_promptor_git_async_init() {
    # Clean up on exit
    trap '__bash_promptor_git_async_cleanup' EXIT
    # Remove stale file
    rm -f "$__BASH_PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null
}

__bash_promptor_git_async_cleanup() {
    if [[ -n "$__BASH_PROMPTOR_GIT_ASYNC_PID" ]]; then
        kill "$__BASH_PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
        wait "$__BASH_PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
    fi
    rm -f "$__BASH_PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null
}

# --- Launch async git worker ---
__bash_promptor_git_async_launch() {
    # Kill previous worker if still running
    if [[ -n "$__BASH_PROMPTOR_GIT_ASYNC_PID" ]]; then
        kill "$__BASH_PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
        wait "$__BASH_PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
    fi

    # Launch background worker; sends SIGUSR1 to parent shell when done
    local parent_pid=$$
    (
        __bash_promptor_git_compute_status
        # Signal the parent shell to refresh the prompt with updated git status
        kill -USR1 "$parent_pid" 2>/dev/null
    ) &
    __BASH_PROMPTOR_GIT_ASYNC_PID=$!
    __BASH_PROMPTOR_GIT_ASYNC_PWD="$PWD"
    disown "$__BASH_PROMPTOR_GIT_ASYNC_PID" 2>/dev/null
}

# --- Read async result ---
# Returns: "bg fg content" or empty
__bash_promptor_segment_git_async() {
    if [[ "${bash_promptor_config[git]}" != true ]]; then
        return
    fi

    local result=""
    local worker_running=false

    # Check if the previous worker is still running
    if [[ -n "$__BASH_PROMPTOR_GIT_ASYNC_PID" ]] && kill -0 "$__BASH_PROMPTOR_GIT_ASYNC_PID" 2>/dev/null; then
        worker_running=true
    fi

    # Check if background worker has finished (file exists and is from current dir)
    if [[ -f "$__BASH_PROMPTOR_GIT_ASYNC_FILE" ]]; then
        local cached_pwd
        cached_pwd=$(head -1 "$__BASH_PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null)
        if [[ "$cached_pwd" == "$PWD" ]]; then
            result=$(tail -n +2 "$__BASH_PROMPTOR_GIT_ASYNC_FILE" 2>/dev/null)
        fi
    fi

    # Launch a new async worker for the next prompt (skip during SIGUSR1 refresh
    # to avoid an infinite loop: worker→SIGUSR1→build_prompt→launch→worker→…)
    if [[ "$__BASH_PROMPTOR_GIT_ASYNC_REFRESHING" != true ]]; then
        __bash_promptor_git_async_launch
    fi

    # If we have a cached result, show it (with wait indicator if worker is still running)
    if [[ -n "$result" ]]; then
        if [[ "$worker_running" == true ]]; then
            # Append wait character to show the result is stale/refreshing
            local wait_char="${bash_promptor_config[git.async.wait.character]}"
            echo "$result ${wait_char}"
        else
            echo "$result"
        fi
    elif [[ "$worker_running" == true ]] || [[ "$__BASH_PROMPTOR_GIT_ASYNC_PWD" == "$PWD" ]]; then
        # No cached result yet but we're in a git repo (worker was just launched)
        # Show wait indicator
        local wait_bg="${bash_promptor_config[git.async.wait.bg]}"
        local wait_fg="${bash_promptor_config[git.async.wait.fg]}"
        local wait_char="${bash_promptor_config[git.async.wait.character]}"
        echo "$wait_bg $wait_fg $wait_char"
    fi
}

# --- Synchronous git segment (alternative, no async) ---
__bash_promptor_segment_git() {
    if [[ "${bash_promptor_config[git]}" != true ]]; then
        return
    fi

    __bash_promptor_git_compute_status_inline
}

# --- Core git status computation (writes to async file) ---
__bash_promptor_git_compute_status() {
    local output
    output=$(__bash_promptor_git_compute_status_inline)

    if [[ -n "$output" ]]; then
        printf '%s\n%s\n' "$PWD" "$output" > "$__BASH_PROMPTOR_GIT_ASYNC_FILE"
    else
        printf '%s\n\n' "$PWD" > "$__BASH_PROMPTOR_GIT_ASYNC_FILE"
    fi
}

# --- Core git status computation (inline, returns "bg fg content") ---
__bash_promptor_git_compute_status_inline() {
    __bash_promptor_git_cmd() {
        GIT_OPTIONAL_LOCKS=0 command git "$@"
    }

    # Get basic info from git rev-parse
    local rev_parse
    rev_parse=$(__bash_promptor_git_cmd rev-parse --git-dir \
        --is-inside-git-dir --is-bare-repository --is-inside-work-tree \
        --short HEAD 2>/dev/null)
    local rev_parse_exit=$?

    if [[ -z "$rev_parse" ]]; then
        return
    fi

    # Parse rev-parse output (bottom to top)
    local rev_parse_short=""
    local rev_parse_is_inside_work_tree=""
    local rev_parse_is_bare_repository=""
    local rev_parse_is_inside_git_dir=""
    local rev_parse_git_dir=""

    if [[ $rev_parse_exit -eq 0 ]]; then
        rev_parse_short="${rev_parse##*$'\n'}"
        rev_parse="${rev_parse%$'\n'*}"
    fi
    rev_parse_is_inside_work_tree="${rev_parse##*$'\n'}"
    rev_parse="${rev_parse%$'\n'*}"
    rev_parse_is_bare_repository="${rev_parse##*$'\n'}"
    rev_parse="${rev_parse%$'\n'*}"
    rev_parse_is_inside_git_dir="${rev_parse##*$'\n'}"
    rev_parse="${rev_parse%$'\n'*}"
    rev_parse_git_dir="${rev_parse##*$'\n'}"

    # Check if pwd is ignored
    if [[ "$rev_parse_is_inside_work_tree" == true ]] &&
       [[ "${bash_promptor_config[git.hide_if_pwd_ignored]}" == true ]] &&
       __bash_promptor_git_cmd check-ignore -q .; then
        return
    fi

    # Collect counts in parallel using subshells
    local count_dirty=0
    local count_added=0
    local count_stash=0
    local count_untracked=0
    local count_upstream=""

    if [[ "$rev_parse_is_inside_work_tree" == true ]]; then
        count_dirty=$(__bash_promptor_git_cmd diff --name-only --no-ext-diff 2>/dev/null | wc -l)
        count_added=$(__bash_promptor_git_cmd diff --name-only --no-ext-diff --cached 2>/dev/null | wc -l)
        count_stash=$(__bash_promptor_git_cmd rev-list --walk-reflogs --count refs/stash 2>/dev/null || echo 0)
        count_untracked=$(__bash_promptor_git_cmd ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' 2>/dev/null | wc -l)
        count_upstream=$(__bash_promptor_git_cmd rev-list --count --left-right "@{upstream}...HEAD" 2>/dev/null)
    fi

    # Trim whitespace from wc -l output
    count_dirty="${count_dirty#"${count_dirty%%[![:space:]]*}"}"
    count_added="${count_added#"${count_added%%[![:space:]]*}"}"
    count_stash="${count_stash#"${count_stash%%[![:space:]]*}"}"
    count_untracked="${count_untracked#"${count_untracked%%[![:space:]]*}"}"

    # Read helper for git dir files
    __bash_promptor_git_dir_read() {
        [[ -r "$rev_parse_git_dir/$1" ]] && IFS=$'\r\n' read -r "$2" < "$rev_parse_git_dir/$1"
    }

    # Determine branch and state
    local detached=""
    local hashed=""
    local branch=""
    local rebase_num=""
    local rebase_total=""
    local rebase_action=""
    local sequencer_todo=""

    if [[ -d "$rev_parse_git_dir/rebase-merge" ]]; then
        __bash_promptor_git_dir_read "rebase-merge/head-name" branch
        __bash_promptor_git_dir_read "rebase-merge/msgnum" rebase_num
        __bash_promptor_git_dir_read "rebase-merge/end" rebase_total
        rebase_action="REBASE"
    elif [[ -d "$rev_parse_git_dir/rebase-apply" ]]; then
        __bash_promptor_git_dir_read "rebase-apply/next" rebase_num
        __bash_promptor_git_dir_read "rebase-apply/last" rebase_total
        if [[ -f "$rev_parse_git_dir/rebase-apply/rebasing" ]]; then
            __bash_promptor_git_dir_read "rebase-apply/head-name" branch
            rebase_action="REBASE"
        elif [[ -f "$rev_parse_git_dir/rebase-apply/applying" ]]; then
            rebase_action="REBASE-APPLYING"
        else
            rebase_action="REBASE/APPLYING"
        fi
    elif [[ -f "$rev_parse_git_dir/MERGE_HEAD" ]]; then
        rebase_action="MERGE"
    elif [[ -f "$rev_parse_git_dir/CHERRY_PICK_HEAD" ]]; then
        rebase_action="CHERRY-PICK"
    elif [[ -f "$rev_parse_git_dir/REVERT_HEAD" ]]; then
        rebase_action="REVERT"
    elif __bash_promptor_git_dir_read "sequencer/todo" sequencer_todo; then
        case "$sequencer_todo" in
            p[\ \	]*|pick[\ \	]*)
                rebase_action="CHERRY-PICK" ;;
            revert[\ \	]*)
                rebase_action="REVERT" ;;
        esac
    elif [[ -f "$rev_parse_git_dir/BISECT_LOG" ]]; then
        rebase_action="BISECT"
    fi

    # Determine branch name if not set by rebase
    if [[ -z "$branch" ]]; then
        if [[ -h "$rev_parse_git_dir/HEAD" ]]; then
            branch=$(__bash_promptor_git_cmd symbolic-ref HEAD 2>/dev/null)
        else
            local head=""
            head=$(__bash_promptor_git_cmd symbolic-ref HEAD 2>/dev/null)

            if [[ -z "$head" ]]; then
                detached=true
                case "${bash_promptor_config[git.describe.style]}" in
                    contains)
                        branch=$(__bash_promptor_git_cmd describe --contains HEAD 2>/dev/null) ;;
                    branch)
                        branch=$(__bash_promptor_git_cmd describe --contains --all HEAD 2>/dev/null) ;;
                    tag)
                        branch=$(__bash_promptor_git_cmd describe --tags HEAD 2>/dev/null) ;;
                    describe)
                        branch=$(__bash_promptor_git_cmd describe HEAD 2>/dev/null) ;;
                    *)
                        branch=$(__bash_promptor_git_cmd describe --tags --exact-match HEAD 2>/dev/null) ;;
                esac
                if [[ $? -ne 0 ]] || [[ -z "$branch" ]]; then
                    hashed=true
                    branch="${rev_parse_short}..."
                fi
                branch="($branch)"
            else
                branch="$head"
            fi
        fi
    fi

    # Strip refs/heads/ prefix
    branch="${branch##refs/heads/}"

    # Build rebase action string
    if [[ -n "$rebase_num" ]] && [[ -n "$rebase_total" ]]; then
        rebase_action="$rebase_action $rebase_num/$rebase_total"
    fi

    # Check for conflicts
    local conflict=false
    if [[ -n "$(__bash_promptor_git_cmd ls-files --unmerged 2>/dev/null)" ]]; then
        conflict=true
    fi

    # Parse upstream counts
    local count_upstream_left=0
    local count_upstream_right=0
    if [[ -n "$count_upstream" ]]; then
        count_upstream_left="${count_upstream%%	*}"
        count_upstream_right="${count_upstream##*	}"
        # Trim
        count_upstream_left="${count_upstream_left#"${count_upstream_left%%[![:space:]]*}"}"
        count_upstream_right="${count_upstream_right#"${count_upstream_right%%[![:space:]]*}"}"
    fi

    # Get configured characters
    local character_dirty="${bash_promptor_config[git.character.dirty]}"
    local character_added="${bash_promptor_config[git.character.added]}"
    local character_untracked="${bash_promptor_config[git.character.untracked]}"
    local character_stash="${bash_promptor_config[git.character.stash]}"
    local character_upstream_left="${bash_promptor_config[git.character.upstream.left]}"
    local character_upstream_right="${bash_promptor_config[git.character.upstream.right]}"
    local character_branch="${bash_promptor_config[git.character.branch]}"
    local character_tag="${bash_promptor_config[git.character.tag]}"
    local character_hash="${bash_promptor_config[git.character.hash]}"
    local character_separator="${bash_promptor_config[git.character.separator]}"
    local character_separator_prompt="${bash_promptor_config[git.character.separator.prompt]}"

    # Build git information string
    local git_string=""
    local info

    for info in ${bash_promptor_config[git.information.sequence]}; do
        case "$info" in
            dirty)
                if [[ "$count_dirty" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${count_dirty}${character_dirty}"
                fi
                ;;
            added)
                if [[ "$count_added" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${count_added}${character_added}"
                fi
                ;;
            untracked)
                if [[ "$count_untracked" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${count_untracked}${character_untracked}"
                fi
                ;;
            stash)
                if [[ "$count_stash" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${count_stash}${character_stash}"
                fi
                ;;
            upstream)
                if [[ "$count_upstream_left" -gt 0 ]] && [[ "$count_upstream_right" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${character_upstream_left}${count_upstream_left}${character_upstream_right}${count_upstream_right}"
                elif [[ "$count_upstream_left" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${character_upstream_left}${count_upstream_left}"
                elif [[ "$count_upstream_right" -gt 0 ]]; then
                    [[ -n "$git_string" ]] && git_string+="$character_separator"
                    git_string+="${character_upstream_right}${count_upstream_right}"
                fi
                ;;
        esac
    done

    # Add special states
    if [[ "$rev_parse_is_inside_git_dir" == true ]]; then
        [[ -n "$git_string" ]] && git_string+=" $character_separator_prompt "
        if [[ "$rev_parse_is_bare_repository" == true ]]; then
            git_string+="BARE"
        else
            git_string+=".GIT"
        fi
    fi
    if [[ -n "$rebase_action" ]]; then
        [[ -n "$git_string" ]] && git_string+=" $character_separator_prompt "
        git_string+="$rebase_action"
    fi
    if [[ "$conflict" == true ]]; then
        [[ -n "$git_string" ]] && git_string+=" $character_separator_prompt "
        git_string+="CONFLICT"
    fi

    # Add branch name
    if [[ -n "$branch" ]]; then
        [[ -n "$git_string" ]] && git_string+=" $character_separator_prompt "
        git_string+="$branch"
        if [[ "$detached" == true ]]; then
            if [[ "$hashed" == true ]]; then
                git_string+="$character_hash"
            else
                git_string+="$character_tag"
            fi
        else
            git_string+=" $character_branch"
        fi
    fi

    # Determine colors based on state priority
    local color_bg="${bash_promptor_config[git.color.bg]}"
    local color_fg="${bash_promptor_config[git.color.fg]}"

    local color_name
    for color_name in ${bash_promptor_config[git.color.sequence]}; do
        case "$color_name" in
            conflict)
                if [[ "$conflict" == true ]] || [[ "$rev_parse_is_inside_git_dir" == true ]]; then
                    color_bg="${bash_promptor_config[git.color.conflict.bg]}"
                    color_fg="${bash_promptor_config[git.color.conflict.fg]}"
                    break
                fi
                ;;
            dirty)
                if [[ "$count_dirty" -gt 0 ]]; then
                    color_bg="${bash_promptor_config[git.color.dirty.bg]}"
                    color_fg="${bash_promptor_config[git.color.dirty.fg]}"
                    break
                fi
                ;;
            added)
                if [[ "$count_added" -gt 0 ]]; then
                    color_bg="${bash_promptor_config[git.color.added.bg]}"
                    color_fg="${bash_promptor_config[git.color.added.fg]}"
                    break
                fi
                ;;
            untracked)
                if [[ "$count_untracked" -gt 0 ]]; then
                    color_bg="${bash_promptor_config[git.color.untracked.bg]}"
                    color_fg="${bash_promptor_config[git.color.untracked.fg]}"
                    break
                fi
                ;;
            detached)
                if [[ "$detached" == true ]]; then
                    color_bg="${bash_promptor_config[git.color.detached.bg]}"
                    color_fg="${bash_promptor_config[git.color.detached.fg]}"
                    break
                fi
                ;;
            remote)
                if [[ "$count_upstream_left" -eq 0 ]] && [[ "$count_upstream_right" -eq 0 ]]; then
                    color_bg="${bash_promptor_config[git.color.remote.bg]}"
                    color_fg="${bash_promptor_config[git.color.remote.fg]}"
                    break
                fi
                ;;
        esac
    done

    echo "$color_bg" "$color_fg" "$git_string"
}
