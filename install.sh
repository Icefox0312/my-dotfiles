#!/bin/bash

# Define paths using $HOME
DOTFILES_DIR="$HOME/my-dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "Starting Dotfiles installation..."

# Create backup directory
echo "Backing up existing directories to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR/bin"

# 1. Handle .config (Full Swap)
if [ -d "$HOME/.config" ] || [ -e "$HOME/.config" ]; then
    echo "Backing up .config..."
    mv "$HOME/.config" "$BACKUP_DIR/"
fi
echo "Linking entire .config folder..."
ln -s "$DOTFILES_DIR/.config" "$HOME/.config"

# 2. Handle .local/bin (Contents Only)
echo "Setting up custom scripts in ~/.local/bin..."
mkdir -p "$HOME/.local/bin"

for script in "$DOTFILES_DIR/.local/bin"/*; do
    # Skip if nothing matches
    [ -e "$script" ] || continue

    script_name=$(basename "$script")
    
    # Backup existing script if it is already there
    if [ -e "$HOME/.local/bin/$script_name" ]; then
        mv "$HOME/.local/bin/$script_name" "$BACKUP_DIR/bin/"
    fi
    
    # Create symlink for the individual script
    ln -s "$script" "$HOME/.local/bin/$script_name"
    
    # Ensure it's executable
    chmod +x "$DOTFILES_DIR/.local/bin/$script_name"
    echo "  -> Linked $script_name"
done

echo "Installation complete!"
