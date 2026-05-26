#!/usr/bin/env bash
# macos/defaults.sh — sensible macOS defaults for a fresh Mac.
#
# Run with:   ./install.sh macos
# Most changes take effect immediately; a few (Finder, Dock, SystemUIServer)
# need the apps to be relaunched — done at the bottom of this script.
#
# Curated from Mathias Bynens' .macos (https://mths.be/macos), pruned to the
# bits that still matter in 2026 and that I actually want.

set -e

# Close System Settings so it doesn't overwrite anything we're about to change.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# Ask for sudo upfront and keep it alive until the script finishes.
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "==> Applying macOS defaults"

###############################################################################
# General UI / UX
###############################################################################

# Disable the startup sound.
sudo nvram SystemAudioVolume=" "

# Expand save and print panels by default.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable auto-correct, smart quotes/dashes, automatic capitalization, period
# substitution — all annoying when typing code or in chats.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

###############################################################################
# Keyboard
###############################################################################

# Fastest possible key repeat. NSGlobalDomain.KeyRepeat = 1 (= 15 ms).
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys (so holding "e" repeats instead of showing accents).
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Full keyboard access for all controls (Tab moves focus to all controls, not just text fields).
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Trackpad
###############################################################################

# Tap-to-click.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three-finger drag.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Screen / screenshots
###############################################################################

# Require password immediately after sleep / screensaver begins.
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to ~/Screenshots (created if missing) as PNGs, no shadow.
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Finder
###############################################################################

# Show all filename extensions, status bar, path bar, hidden files.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true

# Use list view in all Finder windows by default.
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Search the current folder by default (instead of "This Mac").
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Don't write .DS_Store files on network volumes or USB drives.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show the ~/Library folder.
chflags nohidden "${HOME}/Library" 2>/dev/null || true

# Show the /Volumes folder.
sudo chflags nohidden /Volumes

###############################################################################
# Dock
###############################################################################

# Smaller default icon size, autohide, no recent-apps section, faster animation.
defaults write com.apple.dock tilesize -int 44
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2
defaults write com.apple.dock show-recents -bool false

# Don't show Dashboard as a Space (irrelevant on modern macOS, but harmless).
defaults write com.apple.dock dashboard-in-overlay -bool true

# Minimize windows into their app icon.
defaults write com.apple.dock minimize-to-application -bool true

###############################################################################
# Menu bar / clock
###############################################################################

# Show battery percentage.
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

###############################################################################
# Safari (only effective if you ever launch Safari)
###############################################################################

# Show full URL in the address bar.
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true 2>/dev/null || true
# Enable the Develop menu.
defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || true

###############################################################################
# Mac App Store
###############################################################################

# Enable the WebKit developer tools in the Mac App Store.
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Auto-install macOS updates and app updates.
defaults write com.apple.commerce AutoUpdate -bool true

###############################################################################
# Activity Monitor
###############################################################################

# Show the main window when launched.
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
# Sort by CPU usage, descending.
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Photos — don't open automatically when an iPhone is plugged in.
###############################################################################
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Kill affected apps so changes take effect.
###############################################################################
echo "==> Restarting affected apps"
for app in "Activity Monitor" "Dock" "Finder" "SystemUIServer" "cfprefsd"; do
  killall "${app}" >/dev/null 2>&1 || true
done

echo "==> Done. Some changes require a logout or restart to apply."
