# vim: ft=bash

export DNDC_HOME="${DNDC_HOME:-$(dirname "$(realpath "${BASH_SOURCE[0]}")")}"

_container() {
    # TODO: ... there can be only one?
	docker ps --filter "ancestor=$(_image_name)" --format=json |
		jq -r '.Names'
}

_workspace_id() {
  _repo() {
    local -- remote="$(git remote get-url --push origin)"
    python -c 'from sys import argv; from re import match, VERBOSE; p = r"(?:(?:[^@]+@)?[^:/]+:(.+))|(?://(?:[^@]+@)?[^/]+/(.+))"; m = match(p, argv[1], flags=VERBOSE); r = next((g for g in m.groups() if g), "") if m else ""; print("_".join(r.removesuffix(".git").lower().split("/")[-2:]));' "${remote}"
  }
  local -- hash
  hash="$(pwd | md5 | cut -c 1-6)"
  echo "$(_repo)-${hash:0:6}"
}

_image_name() { 
    local -- namespace='localhost/dndc/' basename
    if test -n "${NO_DNDC_NAMESPACES:-}"; then
        namespace=''
    fi
    basename="${PWD##*/}"
    printf '%s%s\n' "${namespace}" "$(_workspace_id)"
}

_prune() {
	if test -n "${NO_DNDC_PRUNE:-}"; then
		docker image prune --force --filter dangling=true
	fi
}

attach() {
	docker exec --interactive --tty $(_container) bash
}

build() {
	down &>/dev/null
    devcontainer build --image-name "$(_image_name)" &&
		_prune
}

debug-build() {
	local -- build_args
	read -r build_args < <(
		jq -r '.build.args | to_entries | map("--build-arg " + .key + "=" + .value) | join(" ")' \
			< ./.devcontainer/devcontainer.json
		echo
	)
	set -x
	docker \
		buildx build --debug --no-cache --progress=plain \
		${build_args} \
		--file="./.devcontainer/$(jq -r .build.dockerfile < .devcontainer/devcontainer.json)" \
		--load \
        --tag="$(_image_name):debug" \
		./.devcontainer
	set +x
	_prune
}

down() {
	# disappointing that 'devcontainer down' is unimplemented
	local -- container
	read -r container < <(_container)
	docker container stop --time 0 ${container}
	docker container remove ${container}
}

exec() {
	docker exec $(_container) bash -c "${@}"
}

alias up='devcontainer up'

dndc() {
	if test -z "$(_container)"; then
		echo '# starting container' 1>&2
		devcontainer up
	fi
	echo '# attaching container' 1>&2
	attach
}

init() {
  # create .devcontainer as needed and install dndc templates
  local -- workspace_id="$(_workspace_id)"
  (
    set -o errexit -o verbose
    if ! test -d ./.devcontainer; then
      mkdir ./.devcontainer
    fi
    cd ./.devcontainer
    eval cp "${DNDC_HOME}/.devcontainer/devcontainer.*" .
    perl -pi -e "s/--pleroo_dndc-000000/--${workspace_id}/g" ./devcontainer.json
  )
}

