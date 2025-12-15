# Alias Hub

**Alias Hub** is a comprehensive collection of shell aliases designed to enhance your terminal productivity. This repository organizes aliases into logical categories, making it easy to find and use commands for specific tasks.

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Installation Options](#installation-options)
  - [What Gets Installed](#what-gets-installed)
  - [Updating](#updating)
  - [System Requirements](#system-requirements)
- [Usage](#usage)
  - [Basic Commands](#basic-commands)
  - [Alias Categories](#alias-categories)
  - [Configuration](#configuration)
- [File Overview](#file-overview)
- [Enhancing Your Terminal Experience](#enhancing-your-terminal-experience)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Modular Design**: Use only the alias categories you need
- **Multi-Platform Support**: Works across different Linux distributions and shells
- **Auto-Detection**: Automatically detects your package manager and shell environment
- **Comprehensive Coverage**: Includes aliases for development, system management, networking, and more
- **Easy Installation**: One-command installation with intelligent setup
- **Backup & Recovery**: Safe installation with automatic backup and restore capabilities
- **Tab Completion**: Built-in autocompletion for alias categories
- **Regular Updates**: Easy update mechanism to stay current with latest aliases

## Getting Started

### Installation

The Alias Hub installer provides a seamless setup experience with automatic detection of your system environment. Choose one of the installation methods below based on your preference and available tools.

#### Quick Installation Methods

**Using `curl` (Recommended):**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)"
```

**Using `wget`:**

```bash
sh -c "$(wget -qO- https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)"
```

**Manual Installation:**

```bash
# Clone the repository
git clone https://github.com/1999AZZAR/alias-hub.git ~/alias-hub

# Navigate to the directory
cd ~/alias-hub

# Run the installer
./install.sh
```

### Installation Options

The installer supports various command-line options for different use cases and environments:

```bash
./install.sh [options]
```

#### Available Options

| Option            | Description                                               |
| ----------------- | --------------------------------------------------------- |
| `--help`        | Show help message and exit                                |
| `--dry-run`     | Preview installation without making changes               |
| `--force`       | Force reinstallation, overwriting existing configurations |
| `--uninstall`   | Remove Alias Hub and restore original configurations      |
| `--no-packages` | Skip system package installation                          |
| `--verbose`     | Enable verbose output for debugging                       |
| `--shell SHELL` | Override automatic shell detection                        |

#### Installation Examples

```bash
# Preview installation without making changes
./install.sh --dry-run

# Force reinstallation (useful for updating)
./install.sh --force

# Install without system packages (minimal setup)
./install.sh --no-packages

# Remove Alias Hub completely
./install.sh --uninstall

# Install with verbose output
./install.sh --verbose

# Force use of specific shell
./install.sh --shell zsh
```

### What Gets Installed

The installer performs the following operations automatically:

1. **Environment Detection**

   - Identifies your package manager (apt, dnf, pacman, apk, zypper, emerge)
   - Detects your shell environment (bash, zsh, fish, ash, dash)
   - Checks for required dependencies
2. **Repository Setup**

   - Downloads Alias Hub to `~/alias-hub`
   - Creates necessary directory structure
   - Sets proper file permissions
3. **Neofetch Configuration**

   - Installs custom Neofetch configuration
   - Downloads ASCII art collection
   - Configures display settings
4. **Package Installation**

   - Installs essential command-line tools:
     - `eza` - Modern replacement for `ls`
     - `htop` - Interactive process viewer
     - `neofetch` - System information tool
     - `fastfetch` - Alternative system info display
     - `ncdu` - Disk usage analyzer
     - `tree` - Directory tree viewer
     - `glances` - System monitoring
     - And many more...
5. **Shell Configuration**

   - Adds Alias Hub sourcing to your shell RC file
   - Enables tab completion for alias categories
   - Creates backups of existing configurations
6. **Autocompletion Setup**

   - Configures tab completion for `alias-list` command
   - Supports completion for all alias categories

### Updating

#### Automatic Updates

To update to the latest version, simply re-run the installer:

```bash
./install.sh
```

The installer will:

- Pull the latest changes from the repository
- Update configurations if needed
- Install any new required packages
- Preserve your customizations

#### Manual Updates

For manual updates:

```bash
cd ~/alias-hub
git pull origin master
```

### System Requirements

#### Supported Package Managers

Alias Hub supports the following package managers:

- **apt** - Ubuntu, Debian, Linux Mint, Pop!_OS, elementary OS
- **dnf** - Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux
- **pacman** - Arch Linux, Manjaro, EndeavourOS, Garuda Linux
- **apk** - Alpine Linux
- **zypper** - openSUSE, SUSE Linux Enterprise
- **emerge** - Gentoo Linux

#### Supported Shells

| Shell              | Configuration File             | Status              |
| ------------------ | ------------------------------ | ------------------- |
| **bash**     | `~/.bashrc`                  | Fully Supported     |
| **zsh**      | `~/.zshrc`                   | Fully Supported     |
| **fish**     | `~/.config/fish/config.fish` | Fully Supported     |
| **ash/dash** | `~/.profile`                 | Supported (limited) |

#### Required Tools

- **`git`** - Version control system for cloning and updating
- **`curl`** or **`wget`** - For downloading remote resources
- **`sudo`** - Administrative privileges for package installation

#### Minimum System Requirements

- **RAM**: 256MB minimum, 512MB recommended
- **Storage**: 50MB free space for installation
- **Network**: Internet connection for package downloads

## Usage

Once installed, Alias Hub provides immediate access to hundreds of useful aliases. Here are the most common usage patterns:

### Basic Commands

After installation, restart your shell or run:

```bash
source ~/.bashrc  # For bash users
source ~/.zshrc   # For zsh users
```

#### Core Commands

```bash
# List all available alias categories
alias-list

# Show aliases in a specific category
alias-list system      # System management aliases
alias-list dev         # Development aliases
alias-list network     # Network aliases

# Get help for any alias (if available)
alias-help [alias-name]
```

### Alias Categories

Alias Hub organizes aliases into logical categories for easy discovery:

#### System Management

```bash
# System information and monitoring
neofetch              # Display system information
fastfetch             # Alternative system info display
sysinfo               # Detailed system information
htop                  # Interactive process viewer
glances               # System monitoring dashboard

# System maintenance
update-system         # Update all system packages
clean-system          # Clean system cache and logs
memory-check          # Check memory usage
disk-usage            # Analyze disk usage
```

#### Development Tools

```bash
# Git operations
gs                    # git status
ga                    # git add
gc                    # git commit
gp                    # git push
gl                    # git log

# Python development
py                    # python3
pip                   # pip with system packages flag
venv-c                # Create virtual environment
venv-a                # Activate virtual environment
pytest                # Run tests with pytest
black                 # Format code with Black

# Docker operations
docker-ps             # Show running containers
docker-images         # List Docker images
docker-clean          # Clean unused containers/images

# Arduino development
arduino-compile       # Compile Arduino sketch
arduino-upload        # Upload to board
arduino-monitor       # Serial monitor

# ESP development
esp-build             # Build ESP-IDF project
esp-flash             # Flash to ESP device
esp-mon               # Serial monitor
```

#### File Management

```bash
# Enhanced listing
ls                    # Colorized, detailed listing (via eza)
ll                    # Long listing format
la                    # Show hidden files
lt                    # Tree view of directories

# File operations
cpv                   # Copy with progress bar
mvv                   # Move with progress bar
rsync-copy            # Rsync with common options
find-large            # Find large files
```

#### Network Management

```bash
# Network information
myip                  # Show public IP address
localip               # Show local IP addresses
ips                   # Show all IPs in color
netstat-listen        # Show listening ports
ping                  # Ping with 5 packets (default)

# Network tools
bandwidth             # Internet speed test
dns-dig               # DNS lookup
port-scan             # Scan local ports
wifi-list             # List WiFi networks
```

#### Database Management

```bash
# PostgreSQL
psql                  # Connect to PostgreSQL
psl                   # List all databases
pgbackup              # Backup database
pgrestore             # Restore database

# Redis
redis start           # Start Redis server
redis stop            # Stop Redis server
redis info            # Show Redis information
redis-cli             # Open Redis CLI
redis-get             # Get key value
redis-set             # Set key value
```

#### ERP & Business Tools

```bash
# Odoo
odoo                  # Start Odoo and open UI
odoo stop             # Stop Odoo
odoo logs             # Show Odoo logs
odoo status           # Check Odoo status
```

### Configuration

#### Custom Aliases

Add your personal aliases to `~/alias-hub/global.alias`:

```bash
# Example custom aliases
alias ll='ls -lah'
alias gs='git status'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
```

#### Configuration Files

Alias Hub creates the following configuration files:

- `~/.config/neofetch/config.conf` - Neofetch configuration
- Shell RC files are modified to include Alias Hub sourcing

#### Backup and Restore

All original configurations are backed up with timestamps:

- Original files: `filename.alias-hub-backup.YYYYMMDD_HHMMSS`
- Restore backups manually or use `--uninstall` option

---

## File Overview

Alias Hub organizes aliases into categorized files for easy management and selective loading. Each file focuses on a specific domain of terminal operations.

### Core Alias Files

| File                                      | Description                      | Key Features                                                     |
| ----------------------------------------- | -------------------------------- | ---------------------------------------------------------------- |
| **`Arduino_CLI.alias`**           | Arduino CLI development          | Board management, core/library installation, compilation, upload |
| **`Development_Tools.alias`**     | Development and coding shortcuts | Git operations, Python, Docker, build tools, Kubernetes          |
| **`ESP_Development.alias`**       | ESP32/ESP8266 development        | ESP-IDF tools, flashing, monitoring, configuration               |
| **`File_Management.alias`**       | File and directory operations    | Enhanced ls, file operations, compression, archive tools         |
| **`Fun_and_Entertainment.alias`** | Entertainment and leisure        | Games, media, fun commands, ASCII art                            |
| **`General_Monitoring.alias`**    | System monitoring and analysis   | Hardware monitoring, performance analysis, resource tracking     |
| **`Github.alias`**                | Git and GitHub operations        | Git shortcuts, GitHub CLI, version control workflows             |
| **`Media_and_Files.alias`**       | Media file handling              | Audio/video processing, conversion tools, YouTube downloads      |
| **`Navigations.alias`**           | Directory navigation             | Quick jumps, bookmarks, directory shortcuts                      |
| **`Network_Management.alias`**    | Network operations               | Connectivity testing, network diagnostics, WiFi management       |
| **`odoo.alias`**                  | Odoo ERP management              | Service control, logs, status monitoring, virtual environment    |
| **`Postgres.alias`**              | PostgreSQL database              | Database administration, queries, backups, monitoring            |
| **`Python.alias`**                | Python development               | Virtual environments, package management, testing, debugging     |
| **`Redis.alias`**                 | Redis database management        | Server control, data operations, monitoring, pub/sub             |
| **`Search_Utilities.alias`**      | Search and find operations       | Enhanced grep, find, locate commands, code search                |
| **`System_Management.alias`**     | System administration            | Updates, monitoring, maintenance tasks, service management       |

### Configuration Files

| File/Directory                              | Purpose                                             |
| ------------------------------------------- | --------------------------------------------------- |
| **`config/neofetch/config.conf`**   | Neofetch display configuration                      |
| **`config/fastfetch/config.jsonc`** | Fastfetch display configuration                     |
| **`script/helpers.sh`**             | Main helper functions loader (modular architecture) |
| **`script/sub_scripts/`**           | Modular helper function scripts                     |
| **`script/system_cleaner.sh`**      | System cleanup automation                           |
| **`script/update_system.sh`**       | System update automation                            |
| **`install.sh`**                    | Installation and setup script                       |
| **`LICENSE`**                       | MIT License file                                    |

### File Details

#### Arduino_CLI.alias

Comprehensive Arduino development aliases for embedded systems programming:

- **Board Management**: Board discovery, attachment, selection
- **Core Management**: Installation for Uno, Nano, Mega, ESP32, ESP8266, and more
- **Library Management**: Library installation, updates, common libraries
- **Compilation & Upload**: Build, verify, and upload commands
- **Monitoring**: Serial monitor with common baud rates
- **Quick Workflows**: Board-specific shortcuts and development helpers

#### Development_Tools.alias

Contains aliases for common development workflows:

- **Git Operations**: Status, add, commit, push, pull, branching
- **Docker**: Container management, image operations, networking
- **Kubernetes**: K8s operations, pod management, deployments
- **Build Tools**: Make, CMake, compiler shortcuts
- **Android/iOS**: Mobile development tools
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins
- **Cloud Development**: AWS, GCP, Azure CLI tools
- **Debugging**: Process monitoring, log analysis, error checking

#### ESP_Development.alias

ESP32/ESP8266 embedded systems development:

- **Environment Setup**: ESP-IDF initialization and updates
- **Build Commands**: Compilation, size analysis, component management
- **Flash Commands**: Upload to devices, erase flash, MAC reading
- **Monitoring**: Serial monitor, logging, GDB debugging
- **Configuration**: Menuconfig, partition management
- **OTA Updates**: Over-the-air update management

#### Github.alias

Comprehensive Git and GitHub CLI operations:

- **Quick Shortcuts**: Memory-friendly short aliases (gs, ga, gc, gp)
- **Descriptive Aliases**: Clear long-form aliases (gstatus, gadd, gcommit)
- **Branching & Merging**: Branch operations, merge strategies
- **Remote Operations**: Push, pull, fetch with various options
- **GitHub CLI**: Issue management, pull requests, repository operations
- **Advanced Features**: Stashing, rebasing, cherry-picking, worktrees

#### General_Monitoring.alias

System monitoring and performance analysis:

- **Hardware Monitoring**: CPU, GPU, memory, disk information
- **Process Monitoring**: Process trees, resource usage, top processes
- **Network Monitoring**: Network statistics, bandwidth usage
- **Container Monitoring**: Docker and Kubernetes monitoring
- **Performance Analysis**: System bottlenecks, I/O statistics
- **Real-time Dashboards**: Live monitoring tools and views

#### odoo.alias

Odoo ERP system management function:

- **Service Control**: Start, stop, restart Odoo service
- **Service Management**: Enable/disable on boot
- **Monitoring**: Logs tailing, status checking
- **Environment**: Python virtual environment activation
- **Interactive Helper**: Color-coded output with help system

#### Postgres.alias

PostgreSQL database management:

- **Database Operations**: Create, drop, list databases
- **Connection Management**: Connect to specific databases
- **Backup & Restore**: Database backups and restoration
- **Monitoring**: Process monitoring, database sizes, table analysis
- **Service Management**: Start, stop, restart PostgreSQL service
- **Logging**: Access to PostgreSQL logs

#### Python.alias

Comprehensive Python development aliases:

- **Package Management**: Pip operations, requirements management
- **Virtual Environments**: Venv creation, activation, management
- **Code Quality**: Black, isort, pylint, mypy formatting and linting
- **Testing**: Pytest, coverage, unittest operations
- **Debugging**: PDB, profiling, memory analysis
- **Data Science**: Jupyter, NumPy, Pandas, Matplotlib
- **Web Development**: Django, Flask, FastAPI commands
- **Deployment**: Package publishing, Docker integration

#### Redis.alias

Redis database management and operations:

- **Server Management**: Start, stop, restart, status (function wrapper)
- **Connection & CLI**: Multiple connection options and CLI modes
- **Key Operations**: Key management, expiration, scanning
- **Data Types**: Strings, Hashes, Lists, Sets, Sorted Sets operations
- **Database Operations**: Database selection, flushing, copying
- **Monitoring**: Real-time monitoring, slowlog, memory statistics
- **Persistence**: Backup, restore, save operations
- **Pub/Sub**: Publish/subscribe messaging
- **Scripting**: Lua script execution and management

#### System_Management.alias

Essential system administration shortcuts:

- **Package Management**: Update, upgrade, clean, search packages
- **System Monitoring**: Process viewing, resource usage, system info
- **Service Management**: Start/stop/restart services, status checks
- **System Cleanup**: Cache clearing, log rotation, temporary file removal
- **Backup Operations**: System backup, configuration backup, recovery

#### Network_Management.alias

Network diagnostics and management tools:

- **Connectivity Testing**: Ping, traceroute, speed tests
- **Network Information**: IP addresses, routing tables, DNS lookup
- **Port Management**: Open ports, listening services, firewall rules
- **Network Tools**: SSH shortcuts, VPN management, proxy settings
- **Security**: Network scanning, security audits, encryption tools

#### File_Management.alias

Enhanced file and directory operations:

- **Listing Commands**: Colorized ls, tree views, detailed information
- **File Operations**: Copy, move, delete with progress indicators
- **Compression**: Archive creation/extraction, multiple formats
- **Search & Find**: File location, content searching, pattern matching
- **Permissions**: Ownership changes, permission management

#### Search_Utilities.alias

Advanced search and discovery tools:

- **Text Search**: Enhanced grep with context, file type filtering
- **File Search**: Find by name, size, date, permissions
- **Content Analysis**: Binary/hex search, encoding detection
- **Indexing**: Locate database updates, fast file location

## Enhancing Your Terminal Experience

Alias Hub works best with a well-configured terminal environment. Here are recommendations for enhancing your setup:

### Terminal Emulators

Consider these modern terminal emulators for the best experience:

- **[Alacritty](https://alacritty.org/)**: GPU-accelerated, highly configurable
- **[Kitty](https://sw.kovidgoyal.net/kitty/)**: Feature-rich with image support
- **[WezTerm](https://wezfurlong.org/wezterm/)**: Cross-platform with Lua configuration
- **[GNOME Terminal**](https://wiki.gnome.org/Apps/Terminal): Default for GNOME desktop
- **[Konsole](https://konsole.kde.org/)**: KDE's powerful terminal emulator

### Shell Frameworks

#### Oh My Bash (for Bash users)

**[Oh My Bash](https://github.com/ohmybash/oh-my-bash)** provides themes and plugins for Bash:

```bash
# Install Oh My Bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Choose a theme (e.g., agnoster, powerline)
# Edit ~/.bashrc and set: OSH_THEME="agnoster"
```

#### Oh My Zsh (for Zsh users)

**[Oh My Zsh](https://ohmyz.sh)** is the most popular Zsh framework:

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install additional plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

Update your `~/.zshrc`:

```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ZSH_THEME="agnoster"  # or your preferred theme
```

### Recommended Plugins

#### Zsh Plugins

- **`zsh-autosuggestions`**: Shows command suggestions based on history
- **`zsh-syntax-highlighting`**: Syntax highlighting for commands
- **`zsh-completions`**: Additional completion definitions
- **`fast-syntax-highlighting`**: Faster, more accurate syntax highlighting

#### Bash Plugins

- **`bash-completion`**: Enhanced tab completion
- **`bash-git-prompt`**: Git status in bash prompt
- **`bash-preexec`**: Pre-exec and post-exec hooks

### Additional Tools

#### Modern Replacements

```bash
# Install modern alternatives
sudo apt install bat ripgrep fd-find fzf  # Ubuntu/Debian
# or
sudo dnf install bat ripgrep fd fzf        # Fedora
# or
sudo pacman -S bat ripgrep fd fzf          # Arch
```

- **`bat`**: A cat clone with syntax highlighting
- **`ripgrep` (rg)**: Fast text search tool
- **`fd`**: Simple, fast, user-friendly find
- **`fzf`**: Fuzzy finder for command line

#### Terminal Multiplexers

- **[tmux](https://github.com/tmux/tmux)**: Terminal multiplexer for session management
- **[screen](https://www.gnu.org/software/screen/)**: Classic terminal multiplexer

#### Text Editors

- **[Neovim](https://neovim.io/)**: Modern Vim-based editor
- **[micro](https://github.com/zyedidia/micro)**: Modern terminal-based editor
- **[helix](https://helix-editor.com/)**: Modal editor inspired by Vim

### Color Schemes and Themes

#### Popular Terminal Themes

1. **Dracula**: Dark theme with high contrast
2. **Nord**: Arctic-inspired color palette
3. **Gruvbox**: Retro groove colors
4. **Solarized**: Carefully crafted color scheme
5. **One Dark**: Inspired by Atom's One Dark theme

#### Font Recommendations

- **Fira Code**: Ligatures and programming symbols
- **JetBrains Mono**: Carefully crafted monospace font
- **Cascadia Code**: Microsoft's monospaced font
- **Hack**: Typeface designed for source code
- **Source Code Pro**: Adobe's monospaced font

### Performance Optimization

#### Terminal Settings

```bash
# Disable scrollback for better performance
# In ~/.inputrc (for readline-based programs)
set enable-bracketed-paste off

# Optimize shell startup
# Remove unnecessary commands from shell RC files
```

#### System Tweaks

```bash
# Increase inotify watches (for file monitoring)
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf

# Optimize SSD (if applicable)
sudo systemctl enable fstrim.timer
```

## Customization

### Personal Aliases

The `global.alias` file is your personal customization space. Add frequently used aliases here:

```bash
# Example custom aliases in ~/alias-hub/global.alias
alias ll='ls -lah --color=auto'
alias gs='git status --short'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push origin main'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias mkdir='mkdir -pv'
```

### Advanced Configuration

#### Conditional Aliases

Create aliases that work across different systems:

```bash
# OS-specific aliases
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias open='xdg-open'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    alias open='open'
fi

# Tool-specific aliases (check if tool exists)
command -v bat >/dev/null && alias cat='bat'
command -v exa >/dev/null && alias ls='exa'
```

#### Function-Based Aliases

For complex operations, use functions:

```bash
# Create a backup function
backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backup created: $1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Git workflow function
gpush() {
    local branch=${1:-main}
    git add .
    git commit -m "${2:-Auto commit}"
    git push origin "$branch"
}
```

### Configuration Management

#### Backup Your Customizations

```bash
# Backup your global.alias before updates
cp ~/alias-hub/global.alias ~/alias-hub/global.alias.backup

# Or use the installer's backup feature
./install.sh --dry-run  # Preview changes
```

#### Sharing Configurations

Consider creating a separate file for work-specific aliases:

```bash
# Create ~/alias-hub/work.alias
alias deploy='ansible-playbook deploy.yml'
alias logs='tail -f /var/log/application.log'
alias ssh-prod='ssh user@production-server'

# Source it conditionally
[[ -f ~/alias-hub/work.alias ]] && source ~/alias-hub/work.alias
```

## Troubleshooting

### Common Issues

#### Installation Problems

**Issue**: Package manager not detected

```
Error: No supported package manager found
```

**Solution**:

```bash
# Install packages manually
sudo apt install git curl  # Ubuntu/Debian
# or
sudo dnf install git curl  # Fedora
```

**Issue**: Permission denied during installation

```
Error: Permission denied
```

**Solution**:

```bash
# Ensure you have sudo access
sudo -v

# Or run without package installation
./install.sh --no-packages
```

#### Alias Loading Issues

**Issue**: Aliases not available after installation

```
Command not found: alias-list
```

**Solution**:

```bash
# Reload your shell configuration
source ~/.bashrc   # Bash
source ~/.zshrc    # Zsh

# Or restart your terminal
```

**Issue**: Tab completion not working

```
No completion for alias-list
```

**Solution**:

```bash
# Check if completion is loaded
complete -p alias-list

# Reload completion
source ~/.bashrc
```

#### Neofetch Issues

**Issue**: Neofetch shows errors

```
Error: ASCII art not found
```

**Solution**:

```bash
# Reinstall Neofetch ASCII art
curl -sSL https://raw.githubusercontent.com/1999AZZAR/neofetch_ascii/master/install.sh | bash

# Or reinstall Alias Hub
./install.sh --force
```

### Diagnostic Commands

```bash
# Check Alias Hub installation
ls -la ~/alias-hub/
cat ~/.bashrc | grep -A 5 "Alias Hub"

# Test package installations
which eza htop neofetch

# Check shell configuration
echo $SHELL
ls -la ~/.bashrc ~/.zshrc
```

### Getting Help

1. **Check the logs**: Run installer with `--verbose` flag
2. **Test individual components**: Try sourcing alias files manually
3. **Check system compatibility**: Verify your OS and shell are supported
4. **Report issues**: Create an issue on GitHub with system information

### Recovery Procedures

#### Restore from Backup

```bash
# List available backups
ls -la ~/.bashrc.alias-hub-backup.*

# Restore specific backup
cp ~/.bashrc.alias-hub-backup.20241212_123000 ~/.bashrc
source ~/.bashrc
```

#### Clean Reinstall

```bash
# Remove Alias Hub completely
./install.sh --uninstall

# Fresh installation
./install.sh
```

#### Manual Cleanup

If automatic uninstall fails:

```bash
# Remove Alias Hub directory
rm -rf ~/alias-hub

# Remove from shell configuration
sed -i '/Alias Hub Configuration/,/End Alias Hub Configuration/d' ~/.bashrc
sed -i '/Alias Hub Configuration/,/End Alias Hub Configuration/d' ~/.zshrc

# Restore Neofetch config
cp ~/.config/neofetch/config.conf.alias-hub-backup.* ~/.config/neofetch/config.conf
```

## Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### Ways to Contribute

#### 1. **Add New Aliases**

- Create aliases for common tasks in your workflow
- Follow existing naming conventions
- Add comments explaining complex aliases
- Test aliases across different systems

#### 2. **Improve Existing Aliases**

- Optimize performance of slow aliases
- Add error handling and safety checks
- Update deprecated commands
- Enhance cross-platform compatibility

#### 3. **Create New Categories**

- Identify underserved areas of terminal work
- Propose new `.alias` files for specific domains
- Ensure new categories follow existing patterns

#### 4. **Bug Reports and Fixes**

- Report bugs with clear reproduction steps
- Include system information and error messages
- Test fixes across multiple environments

#### 5. **Documentation**

- Improve installation instructions
- Add usage examples
- Create tutorials and guides
- Translate documentation

### Development Workflow

#### Setting Up Development Environment

```bash
# Fork the repository
git clone https://github.com/YOUR_USERNAME/alias-hub.git
cd alias-hub

# Create a feature branch
git checkout -b feature/new-aliases

# Make your changes
# ... edit files ...

# Test your changes
./install.sh --dry-run
source ~/.bashrc  # Test aliases

# Commit your changes
git add .
git commit -m "Add new aliases for [category]"
```

#### Code Standards

- **Naming**: Use descriptive, consistent naming for aliases
- **Comments**: Add comments for complex or non-obvious aliases
- **Testing**: Test aliases on multiple systems when possible
- **Safety**: Include safety checks for destructive operations

#### Pull Request Guidelines

1. **Title**: Clear, descriptive title for your changes
2. **Description**: Explain what your PR does and why
3. **Testing**: Describe how you tested your changes
4. **Breaking Changes**: Note any breaking changes
5. **Screenshots**: Include screenshots for UI changes

### Testing Your Changes

```bash
# Test in isolated environment
bash -c 'source ./script/helpers.sh; source ./Development_Tools.alias'

# Check for syntax errors
bash -n *.alias

# Validate with shellcheck (if available)
shellcheck install.sh
```

### Recognition

Contributors will be:

- Listed in `CONTRIBUTORS.md`
- Mentioned in release notes
- Acknowledged in commit messages

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

**Enjoy an optimized and productive terminal experience with Alias Hub!**
