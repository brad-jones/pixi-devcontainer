# Pixi Package Manager (pixi)

<https://pixi.sh/>

Pixi is a package management tool for developers. It allows the developer to
install libraries and applications in a reproducible way. Use pixi
cross-platform, on Windows, Mac and Linux.

## Example Usage (simple install)

Add the feature with the default options to any debian based image & the pixi
CLI tool will be installed. The feature will create a volume mount at
`${containerWorkspaceFolder}/.pixi` and your pixi environment will be installed
inside this volume.

```json
"features": {
    "ghcr.io/brad-jones/pixi-devcontainer/pixi:latest": {}
}
```

_NB: Keep in mind you will be 100% responsible for ensuring all your IDE tooling
has the correct configuration. ie: Simply running `pixi shell` may not be enough
to for example, tell the Golang VsCode extension the `GOROOT`._

## Example Usage (for prebuilds)

With this configuration `pixi install` will be executed at image build time &
thus your pixi environment will be baked into the final image.

Not only does this save time on subsequent container starts the feature also
takes the liberty to make sure the shell is automatically setup. So now things
like the Golang VsCode extension will now see the `GOROOT` environment variable
set correctly.

<https://containers.dev/guide/prebuild>

```json
"build": {
  "dockerfile": "Dockerfile",
  "context": ".."
},
"features": {
    "ghcr.io/brad-jones/pixi-devcontainer/pixi:latest": {
      "workSpaceDir": "${containerWorkspaceFolder}"
    }
}
```

```Dockerfile
FROM mcr.microsoft.com/devcontainers/base:debian
COPY ./pixi.* /pixi/
```

## Options

| Options Id   | Description                                                            | Type   | Default Value      |
| ------------ | ---------------------------------------------------------------------- | ------ | ------------------ |
| version      | The version of pixi to install.                                        | string | latest             |
| workSpaceDir | The directory of the workspace, pixi needs to know this ahead of time. | string | n/a - **REQUIRED** |
