#!/bin/bash

# Show in dock only applications from current space 
#defaults write com.apple.dock wvous-show-windows-in-other-spaces -bool FALSE
# Uncomment to disable this option.
#defaults delete com.apple.dock wvous-show-windows-in-other-spaces

# Show iTunes notification on track changed.
defaults write com.apple.dock itunes-notifications -bool TRUE
defaults write com.apple.dock notification-always-show-image -bool TRUE

killall Dock

# Align horizontaly window buttons in iTunes 10
defaults write com.apple.iTunes full-window -1

# Change company name for XCode comments
defaults write com.apple.Xcode PBXCustomTemplateMacroDefinitions '{"ORGANIZATIONNAME" = "iDR Plus s.r.o.";}'

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
echo "Update /etc/paths if you want to use Homebrew"
tput bel # beep
tput bel # beep
