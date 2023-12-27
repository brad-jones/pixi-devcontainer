#!/usr/bin/bash
set -e

# OPTIONS
# ------------------------------------------------------------------------------
PIXI_VERSION="${VERSION:-"latest"}"
PIXI_ADD_PATH_SHELLRC_FILES="${ADDPATHTOSHELLRCFILES:-true}"
PIXI_DOWNLOAD_URL="https://github.com/prefix-dev/pixi/releases/${PIXI_VERSION}/download/pixi-x86_64-unknown-linux-musl.tar.gz"

# Create a simple wrapper for pixi that modifies XDG_CACHE_HOME but just for
# pixi we we don't want to effect any other tooling installed in the devcontainer
# which may have it's own cache volumes setup.
#
# The only reason we need to do this is it is currently not possible to create
# a mount target with a variable. ie: the ${remoteUser} or their home dir.
# ------------------------------------------------------------------------------
install_pixi_wrapper() {
  cat <<"EOF" >>/usr/bin/pixi
#!/usr/bin/bash
set -e
export XDG_CACHE_HOME="/pixi-cache"
exec /opt/pixi "$@"
EOF
  chmod +x /usr/bin/pixi
}

# Install the script that corrects volume mount permissions & adds pixi PATHs
# It runs whenever a new devcontainer is created for the first time.
# ------------------------------------------------------------------------------
install_pixi_onCreateCommand() {
  cat <<EOF >>/usr/local/share/pixi-onCreateCommand.sh
#!/bin/sh
set -e
PIXI_ADD_PATH_SHELLRC_FILES="$PIXI_ADD_PATH_SHELLRC_FILES"
EOF

  cat <<-"EOF" >>/usr/local/share/pixi-onCreateCommand.sh
# Mounts are created by root so this is our best effort to set permissions
# for the current user so they can write to the volumes.
if [ -n "$USER" ] && [ "$USER" != "root" ]; then
  if command -v sudo >/dev/null; then
    sudo chown -R ${USER} ./.pixi /pixi-cache
  else
    chown -R ${USER} ./.pixi /pixi-cache
  fi
fi

if [ "$PIXI_ADD_PATH_SHELLRC_FILES" = true ]; then
  # Make sure globally installed tools are on PATH
  echo "export PATH=\"\$HOME/.pixi/bin:\$PATH\"" >> "$HOME/.bashrc"
  echo "export PATH=\"\$HOME/.pixi/bin:\$PATH\"" >> "$HOME/.zshrc"
  echo "export PATH=\"\$HOME/.pixi/bin:\$PATH\"" >> "$HOME/.profile"

  # Make sure locally installed tools are on PATH
  echo "export PATH=\"$PWD/.pixi/env/bin:\$PATH\"" >> "$HOME/.bashrc"
  echo "export PATH=\"$PWD/.pixi/env/bin:\$PATH\"" >> "$HOME/.zshrc"
  echo "export PATH=\"$PWD/.pixi/env/bin:\$PATH\"" >> "$HOME/.profile"
fi
EOF

  chmod +x /usr/local/share/pixi-onCreateCommand.sh
}

# Installs the script that either executes pixi install or pixi init when the
# container starts & when it re-starts and the workspace content has changed
# since the last start.
# ------------------------------------------------------------------------------
install_pixi_updateContentCommand() {
  cat <<-"EOF" >>/usr/local/share/pixi-updateContentCommand.sh
#!/bin/sh
set -e

if [ -f "pixi.toml" ]; then
  exec pixi install
fi

pixi init
EOF

  chmod +x /usr/local/share/pixi-updateContentCommand.sh
}

# This actually does the instalation of the pixi command it's self
# ------------------------------------------------------------------------------
install_pixi() {
  mkdir -p /tmp/pixi
  curl -L "${PIXI_DOWNLOAD_URL}" -o /tmp/pixi.tar.gz
  tar -xf /tmp/pixi.tar.gz -C /tmp/pixi
  chmod +x /tmp/pixi/pixi
  mv /tmp/pixi/pixi /opt/pixi
  rm -rf /tmp/pixi /tmp/pixi.tar.gz
}

# The following installs & then uninstall curl if need be
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
  ensure_tar
  ensure_curl
  install_pixi
  install_pixi_wrapper
  install_pixi_onCreateCommand
  install_pixi_updateContentCommand
  clean_curl
  clean_tar
}

main
