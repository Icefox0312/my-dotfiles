#!/bin/bash

# Define paths using $HOME
DOTFILES_DIR="$HOME/my-dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "Starting Dotfiles installation..."

# 1. Install Required Packages
echo "Installing packages..."
# python-pywal is the Arch package name for pywal
sudo pacman -S --needed xdg-user-dirs python-pywal quickshell vscodium

# Update user directories
xdg-user-dirs-update

# 2. Handle .config (Merge contents, replace duplicates, keep existing)
echo "Merging configurations into ~/.config..."
mkdir -p "$HOME/.config"

# rsync merges the folders. 
# -a keeps permissions/structure, -v shows what it's doing
# -b and --backup-dir automatically move overwritten files to the backup folder
rsync -avb --backup-dir="$BACKUP_DIR/.config" "$DOTFILES_DIR/.config/" "$HOME/.config/"

# 3. Handle .local/bin
echo "Merging custom scripts into ~/.local/bin..."
mkdir -p "$HOME/.local/bin"

rsync -avb --backup-dir="$BACKUP_DIR/bin" "$DOTFILES_DIR/.local/bin/" "$HOME/.local/bin/"

# Make all files in the bin directory executable at once
chmod +x "$HOME/.local/bin/"* 2>/dev/null

# 4. Handle Wallpapers
echo "Setting up wallpapers..."
mkdir -p "$HOME/Pictures/Wallpapers"

# Copy contents recursively and quietly ignore if the source folder is empty
cp -r "$DOTFILES_DIR/Wallpaper/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null

echo "Installation complete!"
