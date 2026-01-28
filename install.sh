#!/usr/bin/env bash
# =============================================================================
# Promptor Installation Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation directories
INSTALL_DIR="${HOME}/.local/share/promptor"
CONFIG_DIR="${HOME}/.config/promptor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}"
echo '  ____                            _             '
echo ' |  _ \ _ __ ___  _ __ ___  _ __ | |_ ___  _ __ '
echo ' | |_) |  __/ _ \|  _   _ \|  _ \| __/ _ \|  __|'
echo ' |  __/| | | (_) | | | | | | |_) | || (_) | |   '
echo ' |_|   |_|  \___/|_| |_| |_| .__/ \__\___/|_|   '
echo '                           |_|                  '
echo -e "${NC}"
echo "Powerline Bash Prompt with Async Git Support"
echo "============================================="
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check bash version
check_bash_version() {
    local bash_version="${BASH_VERSION%%.*}"
    if [[ "$bash_version" -lt 4 ]]; then
        print_error "Bash 4.0 or higher is required (you have $BASH_VERSION)"
        exit 1
    fi
    print_status "Bash version check passed ($BASH_VERSION)"
}

# Check for git
check_git() {
    if command -v git &>/dev/null; then
        print_status "Git is installed"
    else
        print_warning "Git not found - git features will be unavailable"
    fi
}

# Check for powerline fonts
check_fonts() {
    echo ""
    echo "Checking for Powerline/Nerd Fonts..."
    echo "Note: For best results, install a Nerd Font:"
    echo "  https://www.nerdfonts.com/"
    echo ""
    echo "Popular options:"
    echo "  - FiraCode Nerd Font"
    echo "  - JetBrainsMono Nerd Font"
    echo "  - Hack Nerd Font"
    echo ""

    read -rp "Do you have a Powerline/Nerd Font installed? [Y/n] " response
    if [[ "$response" =~ ^[Nn] ]]; then
        print_warning "ASCII mode will be used as fallback"
        export PROMPTOR_USE_POWERLINE=0
    else
        print_status "Powerline mode enabled"
    fi
}

# Create directories
create_directories() {
    print_status "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "${CONFIG_DIR}/cache"
}

# Install files
install_files() {
    print_status "Installing files..."

    # Copy main script
    cp "${SCRIPT_DIR}/promptor.bash" "${INSTALL_DIR}/promptor.bash"
    chmod +x "${INSTALL_DIR}/promptor.bash"

    # Copy default config if not exists
    if [[ ! -f "${CONFIG_DIR}/promptor.conf" ]]; then
        cp "${SCRIPT_DIR}/promptor.conf.default" "${CONFIG_DIR}/promptor.conf"
        print_status "Created default configuration at ${CONFIG_DIR}/promptor.conf"
    else
        print_warning "Configuration file exists, not overwriting"
    fi
}

# Add to bashrc
add_to_bashrc() {
    local bashrc="${HOME}/.bashrc"
    local source_line="# Promptor - Powerline Bash Prompt"
    local source_cmd="[[ -f \"${INSTALL_DIR}/promptor.bash\" ]] && source \"${INSTALL_DIR}/promptor.bash\""

    if grep -q "promptor.bash" "$bashrc" 2>/dev/null; then
        print_warning "Promptor already in .bashrc"
    else
        echo "" >> "$bashrc"
        echo "$source_line" >> "$bashrc"
        echo "$source_cmd" >> "$bashrc"
        print_status "Added Promptor to ${bashrc}"
    fi
}

# Uninstall function
uninstall() {
    print_status "Uninstalling Promptor..."

    # Remove installation directory
    rm -rf "$INSTALL_DIR"

    # Remove from bashrc
    local bashrc="${HOME}/.bashrc"
    if [[ -f "$bashrc" ]]; then
        sed -i '/# Promptor - Powerline Bash Prompt/d' "$bashrc"
        sed -i '/promptor\.bash/d' "$bashrc"
    fi

    # Ask about config
    read -rp "Remove configuration directory? [y/N] " response
    if [[ "$response" =~ ^[Yy] ]]; then
        rm -rf "$CONFIG_DIR"
        print_status "Configuration removed"
    else
        print_status "Configuration preserved at ${CONFIG_DIR}"
    fi

    print_status "Promptor uninstalled!"
    echo "Please restart your shell or run: exec bash"
}

# Main installation
main_install() {
    check_bash_version
    check_git
    check_fonts
    create_directories
    install_files
    add_to_bashrc

    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "To activate Promptor, either:"
    echo "  1. Restart your terminal"
    echo "  2. Run: source ~/.bashrc"
    echo ""
    echo "Customization:"
    echo "  - Edit: ${CONFIG_DIR}/promptor.conf"
    echo "  - Or run: promptor::customize"
    echo ""
    echo "For help: promptor::help"
}

# Parse arguments
case "${1:-}" in
    --uninstall|-u)
        uninstall
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h       Show this help"
        echo "  --uninstall, -u  Uninstall Promptor"
        echo ""
        echo "Without options, performs installation."
        ;;
    *)
        main_install
        ;;
esac
