# syntax=docker.io/docker/dockerfile
ARG IMAGE_NAME
ARG IMAGE_TAG
FROM ${IMAGE_NAME}:${IMAGE_TAG} AS base

FROM base AS os_tweaks
SHELL ["/bin/sh", "-c"]
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
set -xeu
if ! getent passwd "${OS_USER}"; then
    addgroup -g "${OS_GID}" "${OS_USER}"
    adduser -D \
        -G "${OS_USER}" \
        -h "${WORKDIR}" \
        -u "${OS_UID}" \
        "${OS_USER}"
    printf '%s:%sn' \
        "${OS_USER}" \
        "$(printf '%s\n' $(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c 32))" |
        chpasswd
fi
packages=$(
    echo '
        bash
        busybox-extras
        coreutils
        delta
        findutils
        git
        grep
        gnupg
        less
        musl
        musl-locales
        musl-locales-lang
        ripgrep
        util-linux
        vim
    ' |
        tr '\n' ' ' |
        xargs
)
apk add ${packages}
##END-RUN
WORKDIR "${WORKDIR}"
USER "${OS_USER}"

# configure persistent history
FROM os_tweaks AS persistent_history
SHELL ["/bin/bash", "-o", "nounset", "-o", "errexit", "-o", "pipefail", "-o", "xtrace", "-c"]
ARG HISTORY_MOUNT
ENV HISTORY_MOUNT="${HISTORY_MOUNT}"
RUN <<##END-RUN
pwd
volume_file="${HISTORY_MOUNT}/.bash_history"
install -Dm 0600 /dev/null "${volume_file}"
if ! test -e ~/.bashrc; then
  install -m=0600 /dev/null ~/.bashrc
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
ENV \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    SHELL='/bin/bash'
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
ENTRYPOINT ["/bin/bash"]
