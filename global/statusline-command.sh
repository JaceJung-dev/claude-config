#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
model=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')

# Get current time
current_time=$(date +%H:%M:%S)

# Model label: display name only, strip " (NNNk context)" / " (NNNM context)" suffix
model_label=$(echo "$model" | sed 's/ *([0-9][0-9]*[KkMm] context)$//')

# ANSI 256-color pastel palette (ANSI-C quoting: $'...' so \033 is interpreted by bash)
C_TIME=$'\033[38;5;223m'      # Pastel peach       (223) - time
C_MODEL=$'\033[38;5;189m'     # Pastel lavender    (189) - model name
C_CTX=$'\033[38;5;157m'       # Pastel green       (157) - context usage
C_FIVE=$'\033[38;5;229m'      # Pastel yellow      (229) - 5h rate limit
C_SEVEN=$'\033[38;5;183m'     # Pastel purple      (183) - 7d rate limit
C_DIR=$'\033[38;5;153m'       # Pastel blue        (153) - directory path
C_GIT=$'\033[38;5;121m'       # Pastel mint        (121) - git branch
C_SEP=$'\033[38;5;240m'       # Dim gray           (240) - separators
C_RESET=$'\033[0m'

# Build context usage info (e.g. "0.0M/1.0M (4%)")
# Show even before first message: if current_usage is absent, treat as 0 tokens used.
context_info=""

# Resolve effective context window size:
# 1) Use value from JSON if present
# 2) Estimate from model display name if not
effective_window=""
if [ -n "$context_window_size" ] && [ "$context_window_size" != "null" ]; then
    effective_window="$context_window_size"
else
    # Estimate from model name keywords
    model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
    case "$model_lower" in
        *opus*4.7*|*opus*4-7*)   effective_window=1048576 ;;  # Opus 4.7: ~1M
        *opus*)                   effective_window=200000  ;;
        *sonnet*4.7*|*sonnet*4-7*) effective_window=200000 ;;
        *sonnet*)                 effective_window=200000  ;;
        *haiku*)                  effective_window=200000  ;;
        *)                        effective_window=""       ;;  # unknown: skip
    esac
fi

if [ -n "$effective_window" ]; then
    # Sum tokens (defaults to 0 when current_usage is absent)
    total_used=$(echo "$input_tokens $cache_read $cache_creation" | awk '{print $1 + $2 + $3}')
    if [ "$effective_window" -ge 1000000 ]; then
        used_str=$(awk "BEGIN {printf \"%.1fM\", $total_used/1000000}")
        max_str=$(awk "BEGIN {printf \"%.1fM\", $effective_window/1000000}")
    else
        used_str=$(awk "BEGIN {printf \"%dK\", $total_used/1000}")
        max_str=$(awk "BEGIN {printf \"%dK\", $effective_window/1000}")
    fi
    used_pct=$(awk "BEGIN {printf \"%d\", ($total_used / $effective_window) * 100 + 0.5}")
    context_info="${C_SEP} | ${C_CTX}💬 ${used_str}/${max_str} (${used_pct}%)${C_RESET}"
fi

# Build rate limit info
# Priority 1: Claude Code JSON rate_limits (official, percentage-based)
# Priority 2: ccusage cost fallback (when rate_limits not available)

five_info=""
seven_info=""

# --- Priority 1: Claude Code JSON rate_limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
seven_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

if [ -n "$five_pct" ]; then
    five_pct_int=$(printf "%.0f" "$five_pct")

    # Calculate remaining time until 5h window resets
    time_str=""
    if [ -n "$five_resets" ] && [ "$five_resets" != "null" ]; then
        now=$(date +%s)
        diff=$((five_resets - now))
        if [ "$diff" -gt 0 ]; then
            d_hrs=$((diff / 3600))
            d_mins=$(( (diff % 3600) / 60 ))
            if [ "$d_hrs" -gt 0 ]; then
                time_str=" (${d_hrs}h${d_mins}m)"
            else
                time_str=" (${d_mins}m)"
            fi
        fi
    fi

    five_info="${C_SEP} | ${C_FIVE}⚡ 5h: ${five_pct_int}%${time_str}${C_RESET}"
fi

if [ -n "$seven_pct" ]; then
    seven_pct_int=$(printf "%.0f" "$seven_pct")

    # Calculate remaining time until 7d window resets
    time_str=""
    if [ -n "$seven_resets" ] && [ "$seven_resets" != "null" ]; then
        now=$(date +%s)
        diff=$((seven_resets - now))
        if [ "$diff" -gt 0 ]; then
            d_days=$((diff / 86400))
            d_hrs=$(( (diff % 86400) / 3600 ))
            if [ "$d_days" -gt 0 ]; then
                time_str=" (${d_days}d${d_hrs}h)"
            else
                time_str=" (${d_hrs}h)"
            fi
        fi
    fi

    seven_info="${C_SEP} | ${C_SEVEN}📅 7d: ${seven_pct_int}%${time_str}${C_RESET}"
fi

# --- Priority 2: ccusage cost fallback (only when rate_limits absent) ---
if [ -z "$five_pct" ] || [ -z "$seven_pct" ]; then
    ccusage_bin=""
    if command -v ccusage > /dev/null 2>&1; then
        ccusage_bin=$(command -v ccusage)
    fi

    if [ -n "$ccusage_bin" ]; then
        # Active block: token-limit percentage or cost fallback (for 5h)
        if [ -z "$five_pct" ]; then
            ccusage_out=$("$ccusage_bin" blocks --active --token-limit max --json 2>/dev/null)

            if [ -n "$ccusage_out" ]; then
                block=$(echo "$ccusage_out" | jq -r '
                    if type == "object" and has("blocks") then .blocks[0]
                    elif type == "array" then .[0]
                    else null
                    end
                ' 2>/dev/null)

                if [ -n "$block" ] && [ "$block" != "null" ]; then
                    # Extract tokenLimitStatus fields
                    tls_limit=$(echo "$block" | jq -r '.tokenLimitStatus.limit // empty' 2>/dev/null)
                    total_tokens=$(echo "$block" | jq -r '.totalTokens // empty' 2>/dev/null)
                    remaining_min=$(echo "$block" | jq -r '.projection.remainingMinutes // empty' 2>/dev/null)
                    cost=$(echo "$block" | jq -r '.costUSD // empty' 2>/dev/null)
                    end_time=$(echo "$block" | jq -r '.endTime // empty' 2>/dev/null)

                    # Build time string from remainingMinutes or endTime
                    time_str=""
                    if [ -n "$remaining_min" ] && [ "$remaining_min" != "null" ]; then
                        rem_int=$(printf "%.0f" "$remaining_min")
                        if [ "$rem_int" -gt 0 ]; then
                            rem_hrs=$((rem_int / 60))
                            rem_mins=$((rem_int % 60))
                            if [ "$rem_hrs" -gt 0 ]; then
                                time_str=" (${rem_hrs}h${rem_mins}m)"
                            else
                                time_str=" (${rem_mins}m)"
                            fi
                        fi
                    elif [ -n "$end_time" ] && [ "$end_time" != "null" ]; then
                        end_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${end_time%%.*}" "+%s" 2>/dev/null)
                        if [ -z "$end_epoch" ]; then
                            end_epoch=$(date -d "$end_time" "+%s" 2>/dev/null)
                        fi
                        if [ -n "$end_epoch" ]; then
                            now=$(date +%s)
                            diff=$((end_epoch - now))
                            if [ "$diff" -gt 0 ]; then
                                d_hrs=$((diff / 3600))
                                d_mins=$(( (diff % 3600) / 60 ))
                                if [ "$d_hrs" -gt 0 ]; then
                                    time_str=" (${d_hrs}h${d_mins}m)"
                                else
                                    time_str=" (${d_mins}m)"
                                fi
                            fi
                        fi
                    fi

                    if [ -n "$tls_limit" ] && [ "$tls_limit" != "null" ] && \
                       [ -n "$total_tokens" ] && [ "$total_tokens" != "null" ]; then
                        # tokenLimitStatus available: show current% only
                        cur_pct=$(awk "BEGIN {printf \"%.1f\", ($total_tokens / $tls_limit) * 100}")
                        five_info="${C_SEP} | ${C_FIVE}⚡ 5h: ${cur_pct}%${time_str}${C_RESET}"
                    elif [ -n "$cost" ]; then
                        # Fallback: cost-based display
                        cost_str=$(printf "\$%.2f" "$cost")
                        five_info="${C_SEP} | ${C_FIVE}⚡ 5h: ${cost_str}${time_str}${C_RESET}"
                    fi
                fi
            fi
        fi

        # 7-day total cost fallback
        if [ -z "$seven_pct" ]; then
            since_epoch=$(date -v-7d "+%Y-%m-%d" 2>/dev/null || date -d "7 days ago" "+%Y-%m-%d" 2>/dev/null)
            ccusage_week=$("$ccusage_bin" blocks --json 2>/dev/null)

            if [ -n "$ccusage_week" ] && [ -n "$since_epoch" ]; then
                week_cost=$(echo "$ccusage_week" | jq -r --arg since "${since_epoch}T00:00:00.000Z" '
                    (
                        if type == "object" and has("blocks") then .blocks
                        elif type == "array" then .
                        else []
                        end
                    ) |
                    [ .[] | select(.startTime >= $since) | .costUSD ] |
                    add // 0
                ' 2>/dev/null)

                if [ -n "$week_cost" ] && [ "$week_cost" != "0" ]; then
                    week_str=$(printf "\$%.2f" "$week_cost")
                    seven_info="${C_SEP} | ${C_SEVEN}📅 7d: ${week_str}${C_RESET}"
                fi
            fi
        fi
    fi
fi

# Resolve project root and build display path
resolve_project_path() {
    local dir="$1"

    # 1. Try git root first
    local git_root
    git_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$git_root" ]; then
        local root_name
        root_name=$(basename "$git_root")
        if [ "$dir" = "$git_root" ]; then
            echo "${root_name}"
        else
            local rel="${dir#$git_root/}"
            echo "${root_name}:${rel}"
        fi
        return
    fi

    # 2. Walk up looking for project marker files
    local check_dir="$dir"
    local found_root=""
    while [ "$check_dir" != "/" ]; do
        for marker in package.json pyproject.toml Cargo.toml go.mod .git; do
            if [ -e "$check_dir/$marker" ]; then
                found_root="$check_dir"
                break 2
            fi
        done
        check_dir=$(dirname "$check_dir")
    done

    if [ -n "$found_root" ]; then
        local root_name
        root_name=$(basename "$found_root")
        if [ "$dir" = "$found_root" ]; then
            echo "${root_name}"
        else
            local rel="${dir#$found_root/}"
            echo "${root_name}:${rel}"
        fi
        return
    fi

    # 3. Fallback: replace HOME with ~
    echo "${dir/#$HOME/~}"
}

dir_display=$(resolve_project_path "$current_dir")

# Get git status (skip optional locks to avoid hanging)
git_info=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" -c core.fileMode=false branch --show-current 2>/dev/null || echo "detached")

    # Check for changes (skip optional locks)
    if git -C "$current_dir" -c core.fileMode=false diff-index --quiet HEAD -- 2>/dev/null; then
        status=""
    else
        status="*"
    fi

    git_info="${C_SEP} | ${C_GIT}🌿 ${branch}${status}${C_RESET}"
fi

# Output with per-segment pastel colors
# Line 1: time | model | context | 5h rate limit | 7d rate limit
# Line 2: directory | git branch
# \n in format string is interpreted by printf directly
printf "%s⏰ %s%s%s | %s%s🤖 %s%s%s%s%s\n%s📂 %s%s%s\n" \
    "$C_TIME" "$current_time" "$C_RESET" \
    "$C_SEP" "$C_RESET" \
    "$C_MODEL" "$model_label" "$C_RESET" \
    "$context_info" "$five_info" "$seven_info" \
    "$C_DIR" "$dir_display" "$C_RESET" \
    "$git_info"
