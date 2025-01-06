# dndc - dndc's not devcontainers

This is a work in progress based upon an informal cli-based docker image build cycle.

---

I recently dug in to [devcontainers/cli](https://github.com/devcontainers/cli)
and yearned to fill a several seemingly blatant gaps in functionality.

## Note

This code is in an early stage and is subject to significant changes on short notice.

## Context

It is very useful to have a feature set including:

- `devcontainer attach`
- `devcontainer build --debug` with mult-stage support
- `devcontainer build --rebuild` including cleanup of dangling images
- `devcontainer down`
- enhanced (or perhaps better understand) `devcontainer exec`

This workflow relies upon the abandonment of the apparently unnecessary focus
on absract image names in conjunction with a little
[jq](https://github.com/jqlang/jq)-fu leveraging [devcontainer.json's
structure](https://containers.dev/implementors/json_reference/).

## Usage

At present usage involves `. dndc.sh` or `source dndc.sh` followed by calls to its functions.

- attach
- build
- debug
- down
- exec
- up

After some of the TODOs are done this could be useful in conjunction with
[direnv](https://direnv.net/) functionality.

## TODO

- establish more formal usage standards
- add postiional argument to debug to --target STAGE
- add git-styled dndc wrapper
- decouple from a single location
- add usage examples
- add intro to dndc
