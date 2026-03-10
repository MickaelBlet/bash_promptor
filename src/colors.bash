#!/usr/bin/env bash
#
# bash_promptor - Colors
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2026 BLET Mickaël.
#

# Color helper functions for 256-color terminal

# Generate foreground color escape (for PS1, wrapped in \[ \])
__bash_promptor_fg() {
    local color="$1"
    if [[ -n "$color" ]]; then
        printf '\[\033[38;5;%sm\]' "$color"
    fi
}

# Generate background color escape (for PS1, wrapped in \[ \])
__bash_promptor_bg() {
    local color="$1"
    if [[ -n "$color" ]]; then
        printf '\[\033[48;5;%sm\]' "$color"
    fi
}

# Reset all colors (for PS1, wrapped in \[ \])
__bash_promptor_reset() {
    printf '\[\033[0m\]'
}

# Generate foreground color escape (raw, no PS1 wrapping)
__bash_promptor_fg_raw() {
    local color="$1"
    if [[ -n "$color" ]]; then
        printf '\033[38;5;%sm' "$color"
    fi
}

# Generate background color escape (raw, no PS1 wrapping)
__bash_promptor_bg_raw() {
    local color="$1"
    if [[ -n "$color" ]]; then
        printf '\033[48;5;%sm' "$color"
    fi
}

# Reset all colors (raw, no PS1 wrapping)
__bash_promptor_reset_raw() {
    printf '\033[0m'
}

# Display the 256 color palette
bash_promptor_colors() {
    local i j k l color
    local str=""

    # Standard colors 0-15
    for i in {0..15}; do
        str+="\033[48;5;${i}m"
        if ((i % 8 == 0)); then
            str+="\033[38;5;231m"
        else
            str+="\033[38;5;232m"
        fi
        ((i < 10)) && str+="  " || str+=" "
        str+="$i"
        str+="\033[0m "
        ((i == 7)) && str+="\n"
    done
    str+="\n\n"

    # 216 color cube 16-231
    for i in {0..1}; do
        for j in {0..5}; do
            for k in {0..2}; do
                for l in {0..5}; do
                    color=$((j * 6 + k * 36 + l + i * 108 + 16))
                    str+="\033[48;5;${color}m"
                    if ((((color - 16) % 36) / 6 > 2)); then
                        str+="\033[38;5;232m"
                    else
                        str+="\033[38;5;231m"
                    fi
                    ((color < 100)) && str+=" "
                    str+="$color"
                    str+="\033[0m "
                done
                ((k < 2)) && str+="  "
            done
            str+="\n"
        done
    done
    str+="\n"

    # Grayscale 232-255
    for i in {232..255}; do
        str+="\033[48;5;${i}m"
        ((i > 243)) && str+="\033[38;5;232m" || str+="\033[38;5;231m"
        str+="$i"
        str+="\033[0m "
        ((i == 243)) && str+="\n"
    done

    echo -e "$str"
}
