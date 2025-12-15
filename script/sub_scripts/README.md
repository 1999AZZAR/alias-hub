# Sub Scripts Module Documentation

This directory contains modular helper function scripts that are automatically loaded by `helpers.sh`.

## Module Overview

Each module file contains related functions organized by functionality:

### Core System Modules

- **package_managers.sh** - Package manager wrappers
  - `apt()` - Automatic sudo wrapper for apt
  - `snap()` - Automatic sudo wrapper for snap
  - `flatpak()` - Conditional sudo wrapper for flatpak

- **system_updates.sh** - System update and maintenance
  - `update()` - Advanced system update script launcher
  - `clean()` - System cleanup script launcher
  - `dis_update()` - Distribution upgrade including OS release

- **system_utilities.sh** - System utility functions
  - `boot_splash()` - Test Plymouth boot splash screen

### Development Tools

- **development_tools.sh** - Development environment wrappers
  - `k` - Kubernetes kubectl shortcut alias
  - `idf()` - ESP-IDF wrapper function
  - `esptool()` - ESPTool wrapper for ESP32

- **python_tools.sh** - Python package management
  - `pip()` - Pip wrapper with --break-system-packages flag

### File Operations

- **archive_tools.sh** - Archive management
  - `extract()` - Extract archives with auto-detection
  - `archive()` - Create archives from files/directories

- **file_management.sh** - Enhanced file operations
  - `cd()` - Enhanced cd with automatic directory listing
  - `mkcd()` - Create directory and change into it
  - `findc()` - Find files by content
  - `rename_ext()` - Batch rename file extensions

### Network & Entertainment

- **network_tools.sh** - Network utilities and web APIs
  - `cw()` - Curl wrapper for silent requests
  - `weather()` - Get weather information
  - `moon()` - Get moon phase information
  - `horo()` - Get daily horoscope
  - `hn()` - Get Hacker News front page
  - `trending_coins()` - Get trending cryptocurrency info

- **entertainment.sh** - Random fun generators
  - `fun()` - Random fun generator (dice, coin, color, quote, joke)

### Utilities

- **ascii_art.sh** - ASCII art generation
  - `ascii()` - ASCII art generator using loopers.sh or figlet

- **power_management.sh** - TLP power management
  - `tlp()` - TLP service management wrapper

## Module Dependencies

Modules are loaded in the following order to satisfy dependencies:

1. package_managers.sh (no dependencies)
2. system_utilities.sh (no dependencies)
3. python_tools.sh (no dependencies)
4. archive_tools.sh (no dependencies)
5. file_management.sh (no dependencies)
6. network_tools.sh (no dependencies)
7. system_updates.sh (uses package_managers.sh)
8. development_tools.sh (no dependencies)
9. ascii_art.sh (no dependencies)
10. entertainment.sh (uses network_tools.sh)
11. power_management.sh (no dependencies)

## Usage

### Automatic Loading

All modules are automatically loaded when you source `helpers.sh`:

```bash
source /path/to/alias-hub/script/helpers.sh
```

### Selective Loading

You can source individual modules directly if you only need specific functionality:

```bash
# Load only package managers
source /path/to/alias-hub/script/sub_scripts/package_managers.sh

# Load only archive tools
source /path/to/alias-hub/script/sub_scripts/archive_tools.sh
```

When loading modules selectively, be aware of dependencies. For example, if you load `entertainment.sh`, you should also load `network_tools.sh` first.

## Adding New Modules

To add a new module:

1. Create a new `.sh` file in this directory
2. Add proper header documentation following the format of existing modules
3. Add the module to the loading sequence in `helpers.sh`
4. Update this README with module information

## Module Structure Template

```bash
# ==============================================================================
# MODULE NAME
# ==============================================================================
# Brief description of the module's purpose.
#
# MODULE: module_name.sh
# LOCATION: script/sub_scripts/module_name.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - function_name() - Description
#
# ==============================================================================

# Function implementations here
```

