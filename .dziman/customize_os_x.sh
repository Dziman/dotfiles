#!/bin/bash

# Change company name for XCode comments
defaults write com.apple.Xcode PBXCustomTemplateMacroDefinitions '{"ORGANIZATIONNAME" = "Dziman LLC";}'

# Disable local backups for Time Machine. http://toti.posterous.com/hidden-local-backups-with-mac-os-x-lion-filli
sudo tmutil disablelocal

# Set sleep time delay to 24 hours(86400 secs). http://www.ewal.net/2012/09/09/slow-wake-for-macbook-pro-retina/
sudo pmset -a standbydelay 86400

# Need to update /etc/paths to support Homebrew 
# /usr/local/bin
# /usr/local/sbin
# /usr/bin
# /bin
# /usr/sbin
# /sbin
tput bel # beep
tput bel # beep
echo "Update /etc/paths and or $PATH in .zshrc if you want to use Homebrew"
tput bel # beep
tput bel # beep
