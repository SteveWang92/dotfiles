#!/bin/bash

echo "Generating the lists of explicitly installed packages in ~/.backup"

pacman -Qe > ~/.dotfiles/backup/pacman_packages || echo "pacman failed"
gem list > ~/.dotfiles/backup/gem_packages || echo "gem failed"
npm list -g --depth=0 > ~/.dotfiles/backup/npm_packages || echo "npm failed"
pip list --format=columns > ~/.dotfiles/backup/pip_packages || echo "pip failed"
cargo --list | tail -n +2 | tr -d " " > ~/.dotfiles/backup/cargo_packages || echo "cargo failed"
ghc-pkg list > ~/.dotfiles/backup/ghc-pkg_packages || echo "ghc-pkg failed"
composer global show | cut -d ' ' -f1 > ~/.dotfiles/backup/composer_packages || echo "composer failed"

git add backup

exit 0
