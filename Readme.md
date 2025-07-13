# Alias Hub

Welcome to **Alias Hub**! This repository organizes a comprehensive collection of shell aliases, categorized to simplify and enhance your workflows. By sourcing these aliases, you can save time, reduce repetitive tasks, and boost your productivity in the terminal.

---

## 🚀 Getting Started

### One-Liner Installation

Run one of the following commands in your terminal to install or update Alias Hub. The script will automatically detect your shell and set everything up.

**Using `curl` (Recommended):**
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)"
```

**Using `wget`:**
```bash
sh -c "$(wget -qO- https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)"
```

The installer will:
1.  Clone or update the repository to `~/alias-hub`.
2.  Set up Neofetch with a custom configuration and ASCII art.
3.  Source the aliases into your `.bashrc` or `.zshrc`.
4.  Install necessary packages like `eza`, `htop`, and `neofetch`.

### Updating

To update to the latest version, simply run the installation command again. The script will automatically pull the latest changes.

---

## 🗂 File Overview

Here’s a summary of the `.alias` files included in this repository:

- **`Development_Tools.alias`**: Shortcuts for coding, debugging, and developer tools.
- **`ESP_Development.alias`**: Aliases tailored for ESP-based development tasks.
- **`File_Management.alias`**: Utilities for file and directory management.
- **`Fun_and_Entertainment.alias`**: Fun commands for casual and entertainment purposes.
- **`global.alias`**: General-purpose aliases that work across all categories.
- **`Media_and_Files.alias`**: Commands for handling media files and related operations.
- **`Navigations.alias`**: Directory navigation shortcuts to streamline movement.
- **`Network_Management.alias`**: Tools for managing and troubleshooting network-related tasks.
- **`Postgres.alias`**: Database management aliases for PostgreSQL users.
- **`Search_Utilities.alias`**: Commands for efficient searching using tools like `grep` and `find`.
- **`System_Management.alias`**: System administration shortcuts to manage processes, updates, and more.

---

## ✨ Enhancing Your Terminal Experience

Take your terminal to the next level with these tools and plugins:

### Install Oh My Bash/Oh My Zsh

- **[Oh My Bash](https://github.com/ohmybash/oh-my-bash):** A framework for managing Bash configurations.
- **[Oh My Zsh](https://ohmyz.sh):** A popular Zsh framework with an extensive plugin ecosystem.

To install:

```bash
# Install Oh My Bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Recommended Plugins

Enhance functionality with these plugins:

- **`zsh-autosuggestions`**: Displays command suggestions as you type.
- **`zsh-syntax-highlighting`**: Highlights syntax for better readability.

To use these plugins, update your `.zshrc`:

```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```

Install plugins via a plugin manager like `antigen` or `zinit`.

---

## 🛠️ Customization

The `global.alias` file is designed for user-specific aliases. Add your personalized shortcuts here to make them always accessible.

Example:

```bash
alias gs='git status'
alias ll='ls -lah'
```

---

## 🌟 Highlights

- **Modular Design:** Use only the categories you need.
- **Ease of Customization:** Add or modify aliases as required.
- **Versatile Coverage:** Includes development, networking, file management, and more.

---

## 🤝 Contributing

We welcome contributions! Here’s how you can help:

1. Add new aliases to existing categories.
2. Propose new categories and `.alias` files.
3. Report issues or bugs via the GitHub repository.

---

Enjoy an optimized and productive terminal experience with Alias Hub!
