#!/bin/bash

# Kill any existing instance of the bar
pkill quickshell
# Launch the new bar in the background
quickshell -p ~/.config/quickshell/bar/ &