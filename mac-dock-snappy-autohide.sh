#!/bin/bash
# Dock auto-hide with near-instant delay
# Prevents the dock from migrating to other monitors while keeping it snappy
defaults write com.apple.dock autohide -bool true && \
defaults write com.apple.dock autohide-delay -float 0.0001 && \
killall Dock
