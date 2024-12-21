# Aliases Collection

Welcome to the `aliases` collection! This repository organizes shell aliases into categories, making it easy for anyone to streamline their workflows. Simply source the aliases you need and start saving time on repetitive tasks.

## 📂 Directory Structure

Here’s an overview of the `.alias` files and their purposes:

- **`Development_Tools.alias`**: Aliases for coding, debugging, and development-related tools.
- **`ESP_Development.alias`**: Specific aliases for ESP development tasks.
- **`File_Management.alias`**: Handy shortcuts for managing files and directories.
- **`Fun_and_Entertainment.alias`**: Fun or entertainment-related commands for a lighter mood.
- **`global.alias`**: A collection of user-custom aliases applicable across all categories.
- **`Media_and_Files.alias`**: Aliases for managing media files and related operations.
- **`Navigations.alias`**: Quick navigation shortcuts for directories and paths.
- **`Network_Management.alias`**: Tools and commands for managing networks.
- **`Search_Utilities.alias`**: Aliases for search-related tasks (grep, find, etc.).
- **`System_Management.alias`**: Commands to manage your system efficiently.

## 🚀 How to Use

### 1. Clone the Repository (put on your home dir to make it ease).
Clone the repository to your local machine:
```bash
git clone https://github.com/1999AZZAR/alias-hub
cd alias-hub
```

### 2. Source the Aliases
To use the aliases, you need to source them in your shell configuration file.

#### For Bash:
Add the following line to your `~/.bashrc`:
```bash
for file in ~/alias-hub*.alias; do source "$file"; done
```

#### For Zsh:
Add the following to your `~/.zshrc`:
```bash
for file in ~/alias-hub*.alias; do source "$file"; done
```

#### For Fish:
Use a loop in your Fish configuration:
```fish
for file in ~/alias-hub/*.alias
    source $file
end
```

### 3. Reload Your Shell
Apply the changes by reloading your shell:
```bash
source ~/.bashrc  # For Bash
source ~/.zshrc   # For Zsh
exec fish         # For Fish
```

## 🛠️ Customization
The `global.alias` file is designed for user-specific aliases. Add your personal favorites here to ensure they are always available.

Example:
```bash
alias ll='exa -l --icons --group-directories-first'
alias gs='git status'
```

## 🌟 Highlights
- Modular design allows you to use only the categories you need.
- Highly customizable and easy to extend with new aliases.
- Covers common use cases like development, networking, file management, and more.

## 🤝 Contributions
Feel free to contribute by:
- Adding new aliases to existing categories.
- Proposing new categories and creating `.alias` files for them.
- Reporting bugs or issues via GitHub.

---

Enjoy your enhanced shell experience!
