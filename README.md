# pixi DevContainer

## What is pixi?

Pixi is a package management tool for developers. It allows the developer to
install libraries and applications in a reproducible way. Use pixi
cross-platform, on Windows, Mac and Linux.

see: <https://pixi.sh>

## What is a DevContainer?

A development container (or dev container for short) allows you to use a
container as a full-featured development environment.

see: <https://containers.dev>

## Why do we need both?

_TLDR: So I can use my pixi environment in
[Github Codespaces](https://github.com/features/codespaces) & similar._

A devcontainer is really great at providing a standardized base operating system
for your development environment however as it is a container & containers are
generally built for a single tool or technology often you find yourself wanting
to merge multiple images together in order to support todays ever increasing
multi-technology solutions. eg: add NodeJs to a Go container or vice versa.

In more recent times the emerging devcontainer spec has defined what it calls
_Features_ in an attempt to solve this issue. Read more about devcontainer
Features here: <https://containers.dev/implementors/features>

_This repo supplies a feature for pixi, see:
[./features/src/pixi](https://github.com/brad-jones/pixi-devcontainer/tree/master/features/src/pixi)_

The alternative to a heap of features is use a package manager like `pixi` with
a good base image like say: `mcr.microsoft.com/devcontainers/base:debian`

### Benefits

- You can take your pixi environment with you to places like
  [Github Codespaces](https://github.com/features/codespaces)

- You still have a portable development environment that can be used natively
  without the performance overhead of a container.

## How do I use this?

There are 2 ways this repo supports you to run pixi inside a devcontainer.

### Volume Based _[./features/src/pixi](https://github.com/brad-jones/pixi-devcontainer/tree/master/features/src/pixi)_

That is `<YOUR-WORKSPACE>/.pixi` is stored inside a docker volume.

This is super simple & probably what you should start with if new to either Pixi
or Devcontainers.

Add the following feature to any debian base image.

```json
"features": {
    "ghcr.io/brad-jones/pixi-devcontainer/pixi:latest": {}
}
```

All this does is installs the pixi CLI tool into your image & sets up a docker
volume mounted at `<YOUR-WORKSPACE>/.pixi`.

_^ The downside with this approach is that the `pixi shell` will not be
automatically made available to your IDE. eg: VsCode. And so some extensions may
not function correctly if they can not find the environment variables &/or PATHs
they are looking for._

### Pre Build _[./templates/src/pixi-pre-build](https://github.com/brad-jones/pixi-devcontainer/tree/master/templates/src/pixi-pre-build)_

In contrast this template will bake the pixi environment into the devcontainer
image at build time.

Read more about prebuilds in general here:
<https://containers.dev/guide/prebuild>

To use the template _(assuming you have the devcontainer CLI installed)_.

```
$ devcontainer templates apply \
  --template-id ghcr.io/brad-jones/pixi-devcontainer/pixi-pre-build:latest \
  --workspace-folder .
```

_NB: This will override any existing pixi.toml/lock files in the workspace
folder. Feel free to replace them with your own._

Can't be bothered with the devcontainer CLI just copy the
[.devcontainer](https://github.com/brad-jones/pixi-devcontainer/tree/master/templates/src/pixi-pre-build/.devcontainer)
folder from this repo manually.

- TODO: Add this repo to <https://containers.dev/collections> (then the template
  will appear in VsCode)
