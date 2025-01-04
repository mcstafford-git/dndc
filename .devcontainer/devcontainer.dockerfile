# syntax=docker.io/docker/dockerfile:1.4
ARG IMAGE_NAME
ARG IMAGE_TAG
FROM ${IMAGE_NAME}:${IMAGE_TAG} AS base

FROM base AS os_tweaks
SHELL ["/usr/bin/bash", "-o", "nounset", "-o", "errexit", "-o", "pipefail", "-o", "xtrace", "-c"]
ARG \
    OS_GID='10000' \
    OS_UID='10000' \
    OS_USER='root' \
    WORKDIR="${WORKDIR}"
ENV \
    OS_GID="${OS_GID:?}" \
    OS_UID="${OS_UID:?}" \
    OS_USER="${OS_USER:?}" \
    WORKDIR="${WORKDIR}"
RUN <<##END-RUN
if ! getent passwd "${OS_USER}"; then
    groupadd --gid "${OS_GID}" "${OS_USER}"
    useradd --create-home \
      --home-dir "${WORKDIR}" \
      --uid "${OS_UID}" \
      --gid "${OS_GID}" \
      "${OS_USER}"
fi
packages=(
  ca-certificates
  curl
  git
  gnupg
  kmod
  locales
  netcat-openbsd
  netbase
  tzdata
  vim-nox
  wget
)
apt-get update
apt-get install --no-install-recommends --yes "${packages[@]}"
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
##END-RUN
WORKDIR "${WORKDIR}"
USER "${OS_USER}"

# configure persistent history
FROM os_tweaks AS persistent_history
SHELL ["/usr/bin/bash", "-o", "nounset", "-o", "errexit", "-o", "pipefail", "-o", "xtrace", "-c"]
ARG HISTORY_MOUNT
ENV HISTORY_MOUNT="${HISTORY_MOUNT}"
RUN <<##END-RUN
whoami
pwd
install -d --mode=0700 "${HISTORY_MOUNT}"
volume_file="${HISTORY_MOUNT}/.bash_history"
install --mode=0600 /dev/null "${volume_file}"
if ! test -e ~/.bashrc; then
  install \
      owner="${OS_USER}" \
      group="${OS_USER}" \
      mode=0600 \
      /dev/null ~/.bashrc
fi
lines=(
    ''
    '# devcontainer intra-session persistence'
    "export HISTFILE=${volume_file}"
    "export PROMPT_COMMAND='history -a'"
    ''
)
for ((i=0; i<${#lines[@]}; i++)); do
  echo "${lines[${i}]}"
done |
    tee -a ~/.bashrc
##END-RUN

# presumes the repo is publicly available
# docker run --rm -t --entrypoint=/bin/sh docker.io/alpine/git -c "set -x; ls"
FROM docker.io/alpine/git AS dotfiles
ARG DOTFILES
ENV DOTFILES="${DOTFILES}"
SHELL ["/bin/sh", "-c"]
RUN <<##END-RUN
set -xeu
touch /tmp/dotfiles.tgz
if set | grep -qc 'DOTFILES='; then
    mkdir /tmp/dotfiles
    git clone "${DOTFILES}" /tmp/dotfiles
    tar -C /tmp/dotfiles --exclude ./.git -czvf /tmp/dotfiles.tgz .
fi
##END-RUN

FROM persistent_history AS apply_dotfiles
ENV SHELL='/usr/bin/bash'
RUN --mount=from=dotfiles,source=/tmp/dotfiles.tgz,target=/tmp/dotfiles.tgz,type=bind,readonly <<##END-RUN
if test -s /tmp/dotfiles.tgz; then
    tmp=$(mktemp -d)
    (
        cd "${tmp}" &&
        tar -xf /tmp/dotfiles.tgz
        . ./install.sh
    )
    rm -rf "${tmp}"
fi
##END-RUN
