#!/bin/bash

input=$(cat)

# Model
model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')

# Session name or ID (prefer human-readable name)
session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
if [ -n "$session_name" ]; then
  session_label="$session_name"
elif [ -n "$session_id" ]; then
  session_label="${session_id:0:8}"
else
  session_label="no-session"
fi

# Context usage percentage (pre-calculated)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  context_label=$(printf "context: %.0f%%" "$used_pct")
else
  context_label="context: -"
fi

# Total tokens in session (input + output cumulative)
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_tokens=$((total_input + total_output))
if [ "$total_tokens" -gt 0 ]; then
  if [ "$total_tokens" -ge 1000000 ]; then
    total_label=$(awk "BEGIN { printf \"tokens: %.1fM\", $total_tokens/1000000 }")
  elif [ "$total_tokens" -ge 1000 ]; then
    total_label=$(awk "BEGIN { printf \"tokens: %.1fk\", $total_tokens/1000 }")
  else
    total_label="tokens: ${total_tokens}"
  fi
else
  total_label="tokens: 0"
fi

# Pricing per model ($/M tokens): input, 5m cache write, cache read, output
# Source: https://platform.claude.com/docs/en/docs/about-claude/pricing
model_id=$(echo "$input" | jq -r '.model.id // ""')
today=$(date +%Y%m%d)
case "$model_id" in
  claude-fable-5*|claude-mythos-5*|claude-mythos-preview*)
    price_in=10.00; price_cw=12.50; price_cr=1.00; price_out=50.00 ;;
  claude-opus-4-5*|claude-opus-4-6*|claude-opus-4-7*|claude-opus-4-8*)
    price_in=5.00; price_cw=6.25; price_cr=0.50; price_out=25.00 ;;
  claude-opus-4*|claude-opus-3*|claude-3-opus*)
    price_in=15.00; price_cw=18.75; price_cr=1.50; price_out=75.00 ;;
  claude-sonnet-5*)
    # Introductory pricing through 2026-08-31; reverts to $3/$15 on 2026-09-01
    if [ "$today" -ge 20260901 ]; then
      price_in=3.00; price_cw=3.75; price_cr=0.30; price_out=15.00
    else
      price_in=2.00; price_cw=2.50; price_cr=0.20; price_out=10.00
    fi ;;
  claude-sonnet-4*|claude-sonnet-3*|claude-3-7-sonnet*|claude-3-5-sonnet*)
    price_in=3.00; price_cw=3.75; price_cr=0.30; price_out=15.00 ;;
  claude-haiku-4*)
    price_in=1.00; price_cw=1.25; price_cr=0.10; price_out=5.00 ;;
  claude-haiku-3*|claude-3-5-haiku*)
    price_in=0.80; price_cw=1.00; price_cr=0.08; price_out=4.00 ;;
  *)
    price_in=3.00; price_cw=3.75; price_cr=0.30; price_out=15.00 ;;
esac

# Cost per 1M tokens label (input price as reference for the model)
cost_per_1m_label="$(printf '$%.2f' "$price_in")/1M in, $(printf '$%.2f' "$price_out")/1M out"

# Cost: estimate based on last API call (current_usage)
cur=$(echo "$input" | jq -r '.context_window.current_usage // empty')
if [ -n "$cur" ] && [ "$cur" != "null" ]; then
  inp=$(echo "$cur" | jq -r '.input_tokens // 0')
  out=$(echo "$cur" | jq -r '.output_tokens // 0')
  cache_read=$(echo "$cur" | jq -r '.cache_read_input_tokens // 0')
  cache_write=$(echo "$cur" | jq -r '.cache_creation_input_tokens // 0')
  cost=$(awk "BEGIN { printf \"%.4f\", ($inp * $price_in + $cache_write * $price_cw + $cache_read * $price_cr + $out * $price_out) / 1000000 }")
  cost_label="cost: \$$cost"
else
  cost_label="cost: -"
fi

# Total session cost estimate
total_cost=$(awk "BEGIN { printf \"%.3f\", ($total_input * $price_in + $total_output * $price_out) / 1000000 }")
total_cost_label="total: \$$total_cost"

# Assemble status line with color
printf "\033[0;36m%s\033[0m | \033[0;33msession: %s\033[0m | \033[0;32m%s\033[0m | \033[0;35m%s\033[0m | \033[0;31m%s\033[0m | \033[0;31m%s\033[0m | \033[0;90m%s\033[0m" \
  "$model" "$session_label" "$context_label" "$total_label" "$cost_label" "$total_cost_label" "$cost_per_1m_label"
