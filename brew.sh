#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install some other useful utilities like `sponge`.
brew install moreutils

# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;

# Install `wget` with IRI support.
brew install wget --with-iri

# Install GnuPG to enable PGP-signing commits.
brew install gnupg

# Install more recent versions of some macOS tools.
brew install vim --with-override-system-vi
brew install grep
brew install openssh

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

brew install node
brew install fnm
brew install jq
brew install thefuck

######################################################
# APPS
######################################################

# Devtools
brew install --cask iterm2
brew install --cask visual-studio-code
brew install --cask datagrip
brew install --cask docker

# Browsers
brew install --cask google-chrome
brew install --cask brave-browser

# Comms
brew install --cask slack
brew install --cask telegram
brew install --cask whatsapp
brew install --cask zoom
brew install --cask discord
brew install --cask skype
brew install --cask microsoft-teams

# Utils
brew install --cask 1password
brew install --cask authy
brew install --cask krisp
brew install --cask nordvpn
brew install --cask raycast

# Media
brew install --cask spotify
brew install --cask vlc
brew install --cask transmission

# Remove outdated versions from the cellar.
brew cleanup
