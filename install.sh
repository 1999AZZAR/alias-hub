#!/bin/bash

# Install script for Aliases Collection
# This script downloads the repository, sets up the aliases, configures Neofetch,
# and reloads your shell.

# --- Configuration ---
REPO_URL="https://github.com/1999AZZAR/alias-hub.git"
ALIASES_DIR="$HOME/alias-hub"
NEOFETCH_ASCII_INSTALLER_URL="https://raw.githubusercontent.com/1999AZZAR/neofetch_ascii/master/install.sh"

# --- Helper Functions ---
print_info() {
    echo "INFO: $1"
}

print_warning() {
    echo "WARNING: $1"
}

print_error() {
    echo "ERROR: $1" >&2
    exit 1
}

command_exists() {
    command -v "$1" &> /dev/null
}

# --- Main Script ---

# Step 1: Check for dependencies
print_info "Checking for required tools (git, curl)..."
for cmd in git curl; do
    if ! command_exists "$cmd"; then
        # Recommend installing build-essential or base-devel for a complete environment
        print_error "$cmd is not installed. Please install it (e.g., sudo apt install $cmd) and try again."
    fi
done

# Step 2: Clone or update the alias-hub repository
if [ -d "$ALIASES_DIR/.git" ]; then
    print_info "Alias Hub directory already exists. Pulling latest changes..."
    (cd "$ALIASES_DIR" && git pull) || print_warning "Failed to pull latest changes. Continuing with existing version."
else
    print_info "Cloning the aliases collection..."
    git clone --depth 1 "$REPO_URL" "$ALIASES_DIR" || print_error "Failed to clone repository."
fi

# Make helper scripts executable
print_info "Making scripts executable..."
chmod +x "$ALIASES_DIR/script/helpers.sh"
chmod +x "$ALIASES_DIR/script/system_cleaner.sh"
chmod +x "$ALIASES_DIR/script/update_system.sh"

# Step 3: Set up Neofetch base configuration
print_info "Setting up Neofetch base configuration..."
NEOFETCH_CONFIG_DIR="$HOME/.config/neofetch"
SOURCE_NEOFETCH_CONFIG="$ALIASES_DIR/config/neofetch/config.conf"
DEST_NEOFETCH_CONFIG="$NEOFETCH_CONFIG_DIR/config.conf"

mkdir -p "$NEOFETCH_CONFIG_DIR"

if [ -f "$DEST_NEOFETCH_CONFIG" ] && ! [ -L "$DEST_NEOFETCH_CONFIG" ]; then
    print_info "Backing up existing neofetch config to $DEST_NEOFETCH_CONFIG.bak"
    mv "$DEST_NEOFETCH_CONFIG" "$DEST_NEOFETCH_CONFIG.bak"
fi

print_info "Copying new neofetch config from alias-hub..."
cp "$SOURCE_NEOFETCH_CONFIG" "$DEST_NEOFETCH_CONFIG"

# Step 4: Set up Neofetch ASCII art using the remote installer
print_info "Setting up Neofetch ASCII art by running the remote installer..."
if ! curl -sSL "$NEOFETCH_ASCII_INSTALLER_URL" | bash; then
    print_warning "Neofetch ASCII installer failed. Neofetch might not display ASCII art correctly."
fi

# Step 5: Install required packages
print_info "Installing required packages (eza, htop, etc.)..."
if command_exists apt; then
    sudo apt update && \
    sudo apt install -y eza htop net-tools glances sysstat neofetch inxi ncdu tree zip unzip p7zip-full unrar rar curl nmap speedtest-cli lsof python3-pip python3-venv snapd flatpak
else
    print_warning "apt package manager not found. Skipping package installation. Please install them manually."
fi

# Step 6: Configure aliases in shell rc file
print_info "Configuring shell to use aliases..."
SHELL_RC=""
if [[ $SHELL == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ $SHELL == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    print_warning "Unsupported shell: $SHELL. Please configure manually by adding the following to your shell's rc file:"
    echo -e "\n## Custom aliases\nALIASES_DIR=\"$ALIASES_DIR\"\nsource \"\$ALIASES_DIR/script/helpers.sh\"\nfor file in \"\$ALIASES_DIR\"/*.alias; do source \"\$file\"; done"
    exit 0 # Exit gracefully
fi

# Add sourcing script to the shell rc file
if ! grep -q "source \"\$ALIASES_DIR/script/helpers.sh\"" "$SHELL_RC"; then
    echo -e "\n# --- Alias Hub Configuration ---" >> "$SHELL_RC"
    echo "export ALIASES_DIR=\"$ALIASES_DIR\"" >> "$SHELL_RC"
    echo "source \"\$ALIASES_DIR/script/helpers.sh\"" >> "$SHELL_RC"
    echo "for file in \"\$ALIASES_DIR\"/*.alias; do source \"\$file\"; done" >> "$SHELL_RC"
    print_info "Aliases configured in $SHELL_RC."
else
    print_info "Aliases are already configured in $SHELL_RC."
fi

# Step 7: Add autocompletion for alias-list command
print_info "Configuring autocompletion for alias-list..."
AUTO_COMPLETE_CODE="
# Auto-completion for alias-list command (only for .alias files)
_alias_list_completions() {
    local current_word
    current_word=\"\${COMP_WORDS[COMP_CWORD]}\"
    local alias_files_no_ext
    alias_files_no_ext=\$(find \"\$ALIASES_DIR\" -maxdepth 1 -type f -name '*.alias' -exec basename {} .alias \\\;)
    COMPREPLY=(\$(compgen -W \"\$alias_files_no_ext\" -- \"\$current_word\"))
}
# Enable completion for alias-list
complete -F _alias_list_completions alias-list
"
if ! grep -q "_alias_list_completions" "$SHELL_RC"; then
    echo -e "$AUTO_COMPLETE_CODE" >> "$SHELL_RC"
    echo "# --- End Alias Hub Configuration ---" >> "$SHELL_RC"
    print_info "Autocompletion configured in $SHELL_RC."
else
    print_info "Autocompletion is already configured in $SHELL_RC."
fi

# Step 8: Reload the shell
print_info "Installation complete! Please reload your shell to apply changes: source $SHELL_RC"