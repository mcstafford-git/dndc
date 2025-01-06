# vim: ft=bash

_image() {
    jq -r .image < .devcontainer/devcontainer.json
}

_container() {
    docker ps --format "{{.Names}}" --filter ancestor=$(_image)
}

attach() {
    docker exec --interactive --tty $(_container) bash
}

build() {
    down &> /dev/null
    devcontainer build &&
        docker image prune --force --filter dangling=true
}

debug() {
    local -- build_args tagged_image
    read -r build_args < <(
        jq -r '.build.args | to_entries | map("--build-arg " + .key + "=" + .value) | join(" ")' \
            < ./.devcontainer/devcontainer.json
        echo
    )

    read -r tagged_image < <(
        jq -r .image .devcontainer/devcontainer.json
    )

    set -x
    docker \
        buildx build --debug --no-cache --progress=plain \
        ${build_args} \
        --load \
        --tag=${tagged_image} \
        --file=./.devcontainer/devcontainer.dockerfile \
        ./.devcontainer
    set +x
    docker image prune --force --filter dangling=true
}

down() {
    # disappointing that 'evcontainer down' is unimplemented
    local -- container
    read -r container < <(_container)
    docker container stop --time 0 ${container}
    docker container remove ${container}
}

exec() {
    docker exec $(_container) bash -c "${@}"
}

alias up='devcontainer up'
