#!/bin/sh
set -e

# OPTIONS
# ------------------------------------------------------------------------------
PIXI_VERSION="${VERSION:-"latest"}"
PIXI_DOWNLOAD_URL="https://github.com/prefix-dev/pixi/releases/${PIXI_VERSION}/download/pixi-x86_64-unknown-linux-musl.tar.gz"
PIXI_WORKSPACE_DIR="${WORKSPACEDIR:-"/containerWorkspaceFolder"}"

# This actually does the installation of the pixi command it's self
# ------------------------------------------------------------------------------
install_pixi() {
  echo "installing /usr/bin/pixi"
  ensure_tar
  ensure_curl
  mkdir -p /tmp/pixi
  curl -L "${PIXI_DOWNLOAD_URL}" -o /tmp/pixi.tar.gz
  tar -xf /tmp/pixi.tar.gz -C /tmp/pixi
  chmod +x /tmp/pixi/pixi
  mv /tmp/pixi/pixi /usr/bin/pixi
  rm -rf /tmp/pixi /tmp/pixi.tar.gz
  clean_curl
  clean_tar
}

# ------------------------------------------------------------------------------
install_lifecycle_scripts() {
  echo "instaling /usr/local/share/pixi-onCreateCommand.sh"
  mv ./onCreateCommand.sh /usr/local/share/pixi-onCreateCommand.sh
  chmod +x /usr/local/share/pixi-onCreateCommand.sh
}

# Checks for an existing "/pixi/pixi.toml" file & runs "pixi install"
# to warm up "~/.cache/rattler" so that the "updateContentCommand" that
# also executes "pixi install" will be fast.
# ------------------------------------------------------------------------------
preinstall_pixi_env() {
  if ! [ -f "/pixi/pixi.toml" ]; then
    echo "skipping pixi pre install, /pixi/pixi.toml not found."
    return
  fi

  echo "pre installing pixi environment into /pixi"
  mkdir -p "${PIXI_WORKSPACE_DIR}"
  cp /pixi/pixi.* "${PIXI_WORKSPACE_DIR}/"
  chown -R "${_REMOTE_USER}" "${PIXI_WORKSPACE_DIR}"
  prevDir="$PWD"
  cd "${PIXI_WORKSPACE_DIR}"
  su "${_REMOTE_USER}" -c "pixi install"

  # Would be amazing not to have to resort to using tmux here
  ensure_tmux
  rm -rf /tmp/pixi_env*.sh
  su "${_REMOTE_USER}" -c 'tmux new -d "pixi shell"'
  sleep 1
  PIXI_INIT="$(cat /tmp/pixi_env*.sh)"
  PIXI_INIT="$(echo "${PIXI_INIT}" | sed '/export PATH=.*/d')"
  PIXI_INIT="$(echo "${PIXI_INIT}" | sed '/export PIXI_PROMPT=.*/d')"
  PIXI_INIT="$(echo "${PIXI_INIT}" | sed '/export PS1=.*/d')"
  PIXI_INIT="${PIXI_INIT}\nexport PIXI_PROMPT=\"pixi\""
  PIXI_INIT="${PIXI_INIT}\nexport PS1=\"(\${PIXI_PROMPT}) \$PS1\""
  PIXI_INIT="${PIXI_INIT}\nexport PATH=\"\${CONDA_PREFIX}/bin:\${PATH}\""
  echo "${PIXI_INIT}" >>"${_REMOTE_USER_HOME}/.profile"
  echo "${PIXI_INIT}" >>"${_REMOTE_USER_HOME}/.bashrc"
  echo "${PIXI_INIT}" >>"${_REMOTE_USER_HOME}/.zshrc"
  clean_tmux

  cd "$prevDir"
  rm -rf /pixi
  mv "${PIXI_WORKSPACE_DIR}" /pixi
  chown "${_REMOTE_USER}" /pixi
}

# The following installs & then uninstalls tmux if need be
# ------------------------------------------------------------------------------
installed_tmux=false

ensure_tmux() {
  if command -v tmux >/dev/null; then return; fi

  if command -v apt-get >/dev/null; then
    apt-get update
    apt-get install -y --no-install-recommends tmux
    installed_tmux=true
    return
  fi
}

clean_tmux() {
  if [ "$installed_tmux" = false ]; then return; fi

  if command -v apt-get >/dev/null; then
    apt-get -y purge tmux --auto-remove
    apt-get clean
    return
  fi
}

# The following installs & then uninstalls curl if need be
# ------------------------------------------------------------------------------
installed_curl=false

ensure_curl() {
  if command -v curl >/dev/null; then return; fi

  if command -v apt-get >/dev/null; then
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl
    installed_curl=true
    return
  fi
}

clean_curl() {
  if [ "$installed_curl" = false ]; then return; fi

  if command -v apt-get >/dev/null; then
    apt-get -y purge curl ca-certificates --auto-remove
    apt-get clean
    return
  fi
}

# The following installs & then uninstall tar if need be
# ------------------------------------------------------------------------------
installed_tar=false

ensure_tar() {
  if command -v tar >/dev/null; then return; fi

  if command -v apt-get >/dev/null; then
    apt-get update
    apt-get install -y --no-install-recommends tar
    installed_tar=true
    return
  fi
}

clean_tar() {
  if [ "$installed_tar" = false ]; then return; fi

  if command -v apt-get >/dev/null; then
    apt-get -y purge tar --auto-remove
    apt-get clean
    return
  fi
}

# The main entrypoint of the script
# ------------------------------------------------------------------------------
main() {
  install_pixi
  preinstall_pixi_env
  install_lifecycle_scripts
}

main
