# bash_promptor

A **Powerline prompt for Bash**, inspired by [MickaelBlet/Promptor](https://github.com/MickaelBlet/Promptor) (zsh version).

Features a modular segment system, 256-color support, configurable powerline glyphs, and **async git status** to keep your prompt fast even in large repositories.

## Features

- **Powerline glyphs** - Hard dividers, soft dividers, flames, half-circles, honeycombs, pixels, and more
- **Async git status** - Git information is computed in the background; no prompt lag
- **Color-coded git states** - Conflict, dirty, added, untracked, detached, remote
- **Detailed git info** - Branch, tag, hash, dirty/added/untracked counts, stash count, upstream ahead/behind
- **Git operation awareness** - Rebase, merge, cherry-pick, revert, bisect states
- **Configurable segments** - exit_code, user, host, path, git_async (or sync git)
- **256-color palette** - Full 256-color terminal support
- **Configuration file** - Customize colors, segments, glyphs, and behavior
- **Bash 4+** compatible

## Requirements

- **Bash 4.0+** (for associative arrays)
- A terminal with **256-color support**
- A **Powerline/Nerd Font** for glyph rendering (e.g., [Nerd Fonts](https://www.nerdfonts.com/))

## Installation

```bash
# Clone the repository
git clone https://github.com/MickaelBlet/bash_promptor.git ~/.bash_promptor

# Add to your ~/.bashrc
echo 'source ~/.bash_promptor/bash_promptor.bash' >> ~/.bashrc

# Reload
source ~/.bashrc
```

## Configuration

Create a `bash_promptor.conf` file in the project directory:

```bash
# Segments to display (space-separated)
prompt=exit_code user host path git_async

# Powerline glyph style
prompt.glyph=left_hard_divider

# Path display style: full, short, basename
path.style=short

# User segment
user.bg=240
user.fg=231
user.root.bg=124
user.root.fg=231

# Host segment
host.bg=238
host.fg=231

# Path segment
path.bg=31
path.fg=231

# Git colors by state
git.color.bg=240
git.color.fg=231
git.color.dirty.bg=226
git.color.dirty.fg=232
git.color.added.bg=207
git.color.added.fg=232
git.color.untracked.bg=214
git.color.untracked.fg=232
git.color.conflict.bg=124
git.color.conflict.fg=231
git.color.detached.bg=97
git.color.detached.fg=231
git.color.remote.bg=118
git.color.remote.fg=232
```

### Available Glyph Styles

Use `bash_promptor_glyphs` to display all available glyphs. Set via `prompt.glyph`:

| Name | Description |
|------|-------------|
| `left_hard_divider` | Classic powerline arrow () |
| `left_half_circle_thick` | Rounded separator |
| `left_flame_thick` | Flame effect |
| `left_ice_waveform` | Ice/waveform pattern |
| `left_honeycomb` | Honeycomb pattern |
| `left_pixel_squares` | Pixel squares |
| `left_lego_separator` | Lego block |
| `left_bottom_triangle` | Bottom triangle |
| `left_top_triangle` | Top triangle |

### Git Status Indicators

| Symbol | Meaning |
|--------|---------|
| `M` | Modified (dirty) files count |
| `A` | Added (staged) files count |
| `U` | Untracked files count |
| `S` | Stash count |
| `⭣` | Commits behind upstream |
| `⭡` | Commits ahead of upstream |
|  | Branch |
|  | Tag (detached) |

### Git Color Priority

The git segment background color is determined by the first matching state in `git.color.sequence`:

1. **conflict** (red) - Unmerged files
2. **dirty** (yellow) - Modified files
3. **added** (pink) - Staged files
4. **untracked** (orange) - Untracked files
5. **detached** (purple) - Detached HEAD
6. **remote** (green) - Clean and tracking upstream

## Async Git Status

The `git_async` segment runs git status computation in a **background process**. The result is cached and displayed on the next prompt render. This means:

- First prompt in a new directory shows the **previous cached result** (or nothing)
- Subsequent prompts show the **up-to-date git status**
- The prompt **never blocks** waiting for git

For synchronous behavior, use `git` instead of `git_async` in your `prompt` config.

## Utility Functions

| Function | Description |
|----------|-------------|
| `bash_promptor_reload` | Reload configuration and prompt |
| `bash_promptor_colors` | Display 256-color palette |
| `bash_promptor_glyphs` | Display available powerline glyphs |
| `bash_promptor_config_list` | List all configuration values |

## License

[MIT](LICENSE) - Copyright (c) 2026 BLET Mickaël
