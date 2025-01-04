# vim: ft=bash

# usage: cd /path/to/here; . ./install.sh

test -d ~/.config ||
    mkdir -p ~/.config

cp --recursive ./.config/* ~/.config/

find ~/.config/dotfiles -type f ! -name .inputrc -printf '. %p\n' |
    tee -a ~/.bashrc
