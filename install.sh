#!/bin/bash

# Define paths
DOTFILES_DIR="$HOME/my-dotfiles"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "Starting Dotfiles installation..."

# Create backup directory
echo "Backing up existing configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR/.config"
mkdir -p "$BACKUP_DIR/bin"

# Backup and symlink .config files
echo "Setting up .config files..."
for folder in "$DOTFILES_DIR/.config"/*; do
    # Skip if nothing matches
    [ -e "$folder" ] || continue
    
    folder_name=$(basename "$folder")
    
    # If the folder already exists in ~/.config, back it up first
    if [ -d "$CONFIG_DIR/$folder_name" ] || [ -e "$CONFIG_DIR/$folder_name" ]; then
        mv "$CONFIG_DIR/$folder_name" "$BACKUP_DIR/.config/"
    fi
    
    # Create symlink
    ln -s "$folder" "$CONFIG_DIR/$folder_name"
    echo "  -> Linked $folder_name"
done

# Setup local bin directory
echo "Setting up custom scripts in ~/.local/bin..."
mkdir -p "$BIN_DIR"
for script in "$DOTFILES_DIR/bin"/*; do
    # Skip if nothing matches
    [ -e "$script" ] || continue

    script_name=$(basename "$script")
    
    # Backup existing script
    if [ -e "$BIN_DIR/$script_name" ]; then
        mv "$BIN_DIR/$script_name" "$BACKUP_DIR/bin/"
    fi
    
    # Create symlink
    ln -s "$script" "$BIN_DIR/$script_name"
    # Ensure it's executable
    chmod +x "$DOTFILES_DIR/bin/$script_name"
    echo "  -> Linked $script_name"
done

echo "Installation complete!"
