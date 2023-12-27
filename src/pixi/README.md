# Pixi Package Manager (pixi)

<https://pixi.sh/>

Pixi is a package management tool for developers. It allows the developer to
install libraries and applications in a reproducible way. Use pixi cross-platform,
on Windows, Mac and Linux.

## Example Usage

```json
"features": {
    "ghcr.io/brad-jones/devcontainer-features/pixi:latest": {
      "version": "latest",
      "addPathToShellRcFiles": true
    }
}
```

## Options

| Options Id            | Description                                | Type    | Default Value |
| --------------------- | ------------------------------------------ | ------- | ------------- |
| version               | The version of pixi to install.            | string  | latest        |
| addPathToShellRcFiles | Inject pixi PATHs into any shell rc files. | boolean | latest        |

### `addPathToShellRcFiles`

By default this feature will inject some PATHs _(`~/.pixi/bin` & `${containerWorkspaceFolder}/.pixi/env/bin`)_
into any shell rc files _(`.profile`, `.bashrc`, `.zshrc`)_, while this works most of the time the more robust
thing to do is to modify the `$PATH` before the container has even started but that can only be done with
the `remoteEnv` property in the `devcontainer.json` file.

```json
"features": {
    "ghcr.io/brad-jones/devcontainer-features/pixi:latest": {
      "addPathToShellRcFiles": false
    }
},
"remoteEnv": {
  "PATH": "${containerWorkspaceFolder}/.pixi/env/bin:${containerEnv:PATH}"
},
```
