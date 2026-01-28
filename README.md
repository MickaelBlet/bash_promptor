# Promptor

A powerful, customizable Powerline-style Bash prompt with async Git support and live customization.

![Bash](https://img.shields.io/badge/Bash-4.0%2B-green)
![License](https://img.shields.io/badge/License-MIT-blue)

```
  ____                            _
 |  _ \ _ __ ___  _ __ ___  _ __ | |_ ___  _ __
 | |_) |  __/ _ \|  _   _ \|  _ \| __/ _ \|  __|
 |  __/| | | (_) | | | | | | |_) | || (_) | |
 |_|   |_|  \___/|_| |_| |_| .__/ \__\___/|_|
                           |_|
```

## Features

- **Powerline Style** - Beautiful segmented prompt with powerline glyphs
- **Async Git Status** - Non-blocking git information updates
- **Live Customization** - Interactive menu for real-time prompt customization
- **Highly Configurable** - Extensive configuration options via config file
- **256 Color Support** - Full 256-color palette with named colors
- **Modular Segments** - Mix and match prompt segments
- **ASCII Fallback** - Works without powerline fonts
- **Custom Segments** - Easy to add your own segments

## Screenshots

### Default Theme
```
 user   hostname   ~/projects/myapp    main ✔
 ✔
```

### With Git Status
```
 user   hostname   ~/p/myapp    main ↑2 ✎3 …1
 ✔
```

### SSH Session
```
 user    server   /var/log    main ✖
 ✘
```

## Requirements

- Bash 4.0 or higher
- Git (for git features)
- A [Nerd Font](https://www.nerdfonts.com/) for powerline glyphs (optional, ASCII fallback available)

## Installation

### Quick Install

```bash
git clone https://github.com/MickaelBlet/bash_promptor.git
cd bash_promptor
./install.sh
```

### Manual Install

```bash
# Copy the script
mkdir -p ~/.local/share/promptor
cp promptor.bash ~/.local/share/promptor/

# Create config directory
mkdir -p ~/.config/promptor
cp promptor.conf.default ~/.config/promptor/promptor.conf

# Add to ~/.bashrc
echo 'source ~/.local/share/promptor/promptor.bash' >> ~/.bashrc

# Reload
source ~/.bashrc
```

## Usage

### Live Customization

Run the interactive customization menu:

```bash
promptor::customize
```

This opens a menu where you can:
1. Change prompt layout
2. Toggle powerline/ASCII mode
3. Change path display style
4. Customize segment colors
5. Toggle git options
6. Preview changes
7. Save configuration

### Available Commands

| Command | Description |
|---------|-------------|
| `promptor::customize` | Open live customization menu |
| `promptor::save_config` | Save current configuration |
| `promptor::load_config` | Reload configuration file |
| `promptor::preview` | Preview current prompt |
| `promptor::help` | Show help information |

## Configuration

Configuration file: `~/.config/promptor/promptor.conf`

### Layout

Configure which segments appear in your prompt:

```bash
# Default layout
PROMPTOR_LAYOUT="user host path git_status newline status"

# Minimal layout
PROMPTOR_LAYOUT="path git_status status"

# Full layout
PROMPTOR_LAYOUT="user host virtualenv path git_status jobs newline time status"
```

### Available Segments

| Segment | Description |
|---------|-------------|
| `user` | Current username with icon |
| `host` | Hostname (highlighted for SSH) |
| `path` | Current working directory |
| `git_status` | Git branch and status indicators |
| `virtualenv` | Python virtual environment |
| `node_env` | Node.js environment |
| `jobs` | Background jobs count |
| `status` | Last command exit status |
| `time` | Current time |
| `newline` | Line break for multi-line prompt |

### Path Styles

```bash
# Full path: /home/user/projects/myapp
PROMPTOR_PATH_STYLE="full"

# Shortened: ~/p/myapp
PROMPTOR_PATH_STYLE="short"

# Basename only: myapp
PROMPTOR_PATH_STYLE="basename"
```

### Git Options

```bash
# Enable async git updates (recommended for large repos)
PROMPTOR_ASYNC_ENABLED=1

# Show stash count
PROMPTOR_GIT_SHOW_STASH=1

# Show upstream ahead/behind
PROMPTOR_GIT_SHOW_UPSTREAM=1

# Show numeric counts
PROMPTOR_GIT_SHOW_COUNTS=1
```

### Colors

Colors are specified as `"background foreground"` pairs using 256-color codes or names:

```bash
# Using color codes (0-255)
PROMPTOR_SEGMENT_COLORS[user]="27 255"

# Using color names
PROMPTOR_SEGMENT_COLORS[git_clean]="green black"

# Available named colors
# Basic: black, red, green, yellow, blue, magenta, cyan, white
# Bright: bright_black, bright_red, etc.
# Extended: orange, pink, purple, teal, gray, light_gray, dark_gray
# Solarized: sol_base03, sol_base02, sol_yellow, sol_orange, etc.
```

## Git Status Indicators

| Symbol | Meaning |
|--------|---------|
|  | Branch |
| ➦ | Detached HEAD |
| ↑ | Commits ahead of upstream |
| ↓ | Commits behind upstream |
| ✔ | Staged changes |
| ✎ | Unstaged changes |
| … | Untracked files |
| ✖ | Merge conflicts |
|  | Stashed changes |

## Custom Segments

Create your own segments by defining functions:

```bash
# In your promptor.conf or bashrc

promptor::segment_docker() {
    # Check if docker is running
    if docker info &>/dev/null; then
        local containers=$(docker ps -q | wc -l)
        promptor::segment "33" "255" " ${containers}"
    fi
}

# Add to layout
PROMPTOR_LAYOUT="user host docker path git_status newline status"
```

## Themes

### Minimal

```bash
PROMPTOR_LAYOUT="path git_status status"
PROMPTOR_PATH_STYLE="basename"
```

### Developer

```bash
PROMPTOR_LAYOUT="virtualenv node_env path git_status jobs newline status"
```

### Solarized

```bash
PROMPTOR_SEGMENT_COLORS[user]="235 33"
PROMPTOR_SEGMENT_COLORS[host]="235 37"
PROMPTOR_SEGMENT_COLORS[path]="235 244"
PROMPTOR_SEGMENT_COLORS[git_clean]="64 235"
PROMPTOR_SEGMENT_COLORS[git_dirty]="166 235"
PROMPTOR_SEGMENT_COLORS[git_staged]="136 235"
```

## Troubleshooting

### Characters not displaying correctly

1. Make sure you have a [Nerd Font](https://www.nerdfonts.com/) installed
2. Configure your terminal to use the Nerd Font
3. Or disable powerline mode:
   ```bash
   PROMPTOR_USE_POWERLINE=0
   ```

### Slow prompt in large git repositories

Async mode is enabled by default. If still slow:

```bash
# Increase timeout
PROMPTOR_ASYNC_TIMEOUT=10

# Or disable git features in specific directories
# Add to your bashrc:
if [[ "$PWD" == "/path/to/large/repo"* ]]; then
    PROMPTOR_ASYNC_ENABLED=0
fi
```

### Colors look wrong

- Make sure your terminal supports 256 colors
- Check with: `echo $TERM` (should be `xterm-256color` or similar)
- Set in bashrc: `export TERM=xterm-256color`

## Uninstallation

```bash
./install.sh --uninstall
```

Or manually:

```bash
# Remove files
rm -rf ~/.local/share/promptor
rm -rf ~/.config/promptor  # Optional: keeps config

# Remove from ~/.bashrc
# Delete the line containing 'promptor.bash'
```

## License

MIT License - see [LICENSE](LICENSE) file.

## Credits

Inspired by [MickaelBlet/Promptor](https://github.com/MickaelBlet/Promptor) (ZSH version).

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
