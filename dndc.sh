# vim: ft=bash

_pwd_hash() { sha256 <<< "${PWD}"; }

_container() {
	docker ps --filter "ancestor=$(_image)" --format=json |
		jq -r '.Names'
}

_image() {
	for image in $(docker images -q); do
		if docker inspect "${image}" |
			jq '.[0].Config.Labels.PWD_HASH' |
			grep -qc "$(_pwd_hash)"; then
			echo "${image}"
			break
		fi
	done
}

_prune() {
	if test -n "${RETAIN_DANGLING_IMAGES:-}"; then
		docker image prune --force --filter dangling=true
	fi
}

attach() {
	docker exec --interactive --tty $(_container) bash
}

build() {
	down &>/dev/null
	export PWD_HASH=$(_pwd_hash)
	devcontainer build &&
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
		--tag='localhost/debug-build:latest' \
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
	docker exec $(_image) bash -c "${@}"
}

alias up='devcontainer up'

dndc() {
	export export PWD_HASH="$(_pwd_hash)"
	if test -z "$(_container)"; then
		echo '# starting container' 1>&2
		devcontainer up
	fi
	echo '# attaching container' 1>&2
	attach
}
