# vim: ft=bash
bind -f ~/.config/dotfiles/.inputrc
read -r os_release < <(
    awk -F= '/PRETTY_NAME/ {gsub("\"", ""); print $2;}' /etc/os-release 2>/dev/null || :
)
printf 'This sandbox container(%s) is running %s.\n' \
    "${HOSTNAME}" \
    "${os_release}"
readarray -t workspaces < <(
  find /workspaces \
    -maxdepth 1 \
    -type d \
    -not -path /workspaces \
    -not -path '/workspaces/.*' \
    -printf '- %f\n'
)
if test ${#workspaces[@]} -gt 0; then
  echo "Mounted workspaces include:"
  for ((i=0; i<${#workspaces[@]}; i++)); do
    echo "${workspaces[${i}]}"
  done
fi
