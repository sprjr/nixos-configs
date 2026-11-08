#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Nextcloud/Photos/Wallpapers/Desktop"
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

if [[ -n "$RANDOM_WALLPAPER" ]]; then
	# reload Hyprpaper config with new wallpaper
	hyprctl hyprpaper unload all
	hyprctl hyprpaper preload "$RANDOM_WALLPAPER"
	hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER"
fi
