# shellcheck disable=SC2155
export EDITOR='vim'
export HISTIGNORE='pwd:history:ls:ll'
export LANG='en_US.UTF-8'
export LC_COLLATE='C'
export PS1="\n# ?=\$(printf '%03d' \${?}) \s\v devcontainer:${PWD}\n "
export PS4='# ?=${?} pid=${$} shell=[${SHLVL},${BASH_SUBSHELL}] source=${BASH_SOURCE[0]##*/}:${LINENO} func=${FUNCNAME[0]:-MAIN} COMMAND='
export PS=''
export SHELL="$(command -v bash)"
