#!/bin/bash

# Change company name for XCode comments
defaults write com.apple.Xcode PBXCustomTemplateMacroDefinitions '{"ORGANIZATIONNAME" = "Dziman LLC";}'

# Disable local backups for Time Machine. http://toti.posterous.com/hidden-local-backups-with-mac-os-x-lion-filli
sudo tmutil disablelocal

# Set sleep time delay to 24 hours(86400 secs). http://www.ewal.net/2012/09/09/slow-wake-for-macbook-pro-retina/
sudo pmset -a standbydelay 86400

# Set zsh installed by brew as default shell
# sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

# Use Touch ID for sudo
# sudo nano /etc/pam.d/sudo
# Add first line `auth sufficient pam_tid.so`
