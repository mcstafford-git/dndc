# vim: ft=bash
bind -f ~/.config/dotfiles/.inputrc
read -r os_release < <(
    awk -F= '/PRETTY_NAME/ {gsub("\"", ""); print $2;}' /etc/os-release 2>/dev/null || :
)
printf 'This sandbox container(%s) is running %s.\n' \
    "${HOSTNAME}" \
    "${os_release}"
