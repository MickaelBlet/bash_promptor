#!/usr/bin/env bash
#
# bash_promptor - Glyphs
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#

# Glyph definitions (Powerline / Nerd Font symbols)
declare -gA __bash_promptor_glyph

__bash_promptor_glyph[left_hard_divider]=$'\ue0b0'
__bash_promptor_glyph[left_soft_divider]=$'\ue0b1'
__bash_promptor_glyph[right_hard_divider]=$'\ue0b2'
__bash_promptor_glyph[right_soft_divider]=$'\ue0b3'
__bash_promptor_glyph[left_hard_divider_inverse]=$'\ue0b4'
__bash_promptor_glyph[left_soft_divider_inverse]=$'\ue0b5'
__bash_promptor_glyph[right_hard_divider_inverse]=$'\ue0b6'
__bash_promptor_glyph[right_soft_divider_inverse]=$'\ue0b7'
__bash_promptor_glyph[left_half_circle_thick]=$'\ue0b4'
__bash_promptor_glyph[right_half_circle_thick]=$'\ue0b6'
__bash_promptor_glyph[left_half_circle_thin]=$'\ue0b5'
__bash_promptor_glyph[right_half_circle_thin]=$'\ue0b7'
__bash_promptor_glyph[left_bottom_triangle]=$'\ue0b8'
__bash_promptor_glyph[left_top_triangle]=$'\ue0bc'
__bash_promptor_glyph[right_bottom_triangle]=$'\ue0ba'
__bash_promptor_glyph[right_top_triangle]=$'\ue0be'
__bash_promptor_glyph[left_flame_thick]=$'\ue0c0'
__bash_promptor_glyph[left_flame_thin]=$'\ue0c1'
__bash_promptor_glyph[right_flame_thick]=$'\ue0c2'
__bash_promptor_glyph[right_flame_thin]=$'\ue0c3'
__bash_promptor_glyph[left_pixel_squares]=$'\ue0c4'
__bash_promptor_glyph[right_pixel_squares]=$'\ue0c5'
__bash_promptor_glyph[right_pixel_squares_small]=$'\ue0c5'
__bash_promptor_glyph[left_ice_waveform]=$'\ue0c8'
__bash_promptor_glyph[right_ice_waveform]=$'\ue0ca'
__bash_promptor_glyph[left_honeycomb]=$'\ue0cc'
__bash_promptor_glyph[right_honeycomb]=$'\ue0cd'
__bash_promptor_glyph[left_lego_separator]=$'\ue0ce'
__bash_promptor_glyph[left_lego_separator_thin]=$'\ue0cf'
__bash_promptor_glyph[right_lego_separator]=$'\ue0d0'
__bash_promptor_glyph[right_lego_separator_thin]=$'\ue0d1'
__bash_promptor_glyph[left_trapezoid_top]=$'\ue0d2'
__bash_promptor_glyph[right_trapezoid_top]=$'\ue0d4'

# Display all available glyphs
bash_promptor_glyphs() {
    local key
    local -a keys=()
    for key in "${!__bash_promptor_glyph[@]}"; do
        keys+=("$key")
    done
    IFS=$'\n' keys=($(sort <<<"${keys[*]}")); unset IFS

    printf "\n"
    printf "  \033[1m%-35s  %-10s  %s\033[0m\n" "Name" "Unicode" "Glyph"
    printf "  %-35s  %-10s  %s\n" "-----------------------------------" "----------" "-----"
    for key in "${keys[@]}"; do
        local glyph="${__bash_promptor_glyph[$key]}"
        # Get hex value
        local hex
        hex=$(printf '%s' "$glyph" | od -An -tx1 | tr -d ' \n')
        printf "  %-35s  %-10s  %s\n" "$key" "0x${hex}" "$glyph"
    done
    printf "\n"
}
