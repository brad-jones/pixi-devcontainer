# Pixi Package Manager (pixi-pre-build)

<https://pixi.sh/>

This is a devcontainer template, with the pixi package manager, setup for
[pre building](https://containers.dev/guide/prebuild). As opposed to installing
a pixi environment into a volume.

_NB: The assumption is that a `pixi.toml/lock` file already exist in your
workspace._

## Options

| Options Id  | Description                                                                   | Type   | Default Value        |
| ----------- | ----------------------------------------------------------------------------- | ------ | -------------------- |
| baseImg     | The base image to use, must be glibc based _(& for now a debian derivative)_. | string | debian:bookworm-slim |
| pixiVersion | The version of the pixi binary to install.                                    | string | latest               |
