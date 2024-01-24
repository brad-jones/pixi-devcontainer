#!/bin/sh
set -e

# OPTIONS
# ------------------------------------------------------------------------------
PIXI_VERSION="${VERSION:-"latest"}"
PIXI_DOWNLOAD_V="latest/download"
if [ "${PIXI_VERSION}" != "latest" ]; then
  PIXI_DOWNLOAD_V="download/${PIXI_VERSION}"
fi
PIXI_DOWNLOAD_URL="https://github.com/prefix-dev/pixi/releases/${PIXI_DOWNLOAD_V}/pixi-x86_64-unknown-linux-musl.tar.gz"
PIXI_WORKSPACE_DIR="${WORKSPACEDIR:-"/containerWorkspaceFolder"}"
PIXI_ADDITIONAL_INSTALL_TASK="${ADDITIONALINSTALLTASK:-""}"

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
  cp /pixi/* "${PIXI_WORKSPACE_DIR}/"
  chown -R "${_REMOTE_USER}" "${PIXI_WORKSPACE_DIR}"
  prevDir="$PWD"
  cd "${PIXI_WORKSPACE_DIR}"
  su "${_REMOTE_USER}" -c "pixi install"

  if [ -n "${PIXI_ADDITIONAL_INSTALL_TASK}" ]; then
    echo "running additional install task"
    su "${_REMOTE_USER}" -c "pixi run ${PIXI_ADDITIONAL_INSTALL_TASK}"
  fi

  # Would be amazing not to have to resort to using tmux here
  # We need a sourceable output from pixi, eg: '. $(pixi shell --init)'
  ensure_tmux
  rm -rf /tmp/pixi_env*.sh
  su "${_REMOTE_USER}" -c 'tmux new -d "pixi shell"'
  sleep 1
  PIXI_INIT="$(cat /tmp/pixi_env*.sh)"

  # Modify the PATH slightly so that we can still incorprate PATHs from other
  # sources like devcontainer.json remoteEnv or containerEnv.
  PIXI_INIT="$(echo "${PIXI_INIT}" | sed "s,${PATH},\${PATH},")"

  # De-dupe paths
  # see: https://superuser.com/a/1771082
  PIXI_INIT="${PIXI_INIT}\nif [[ -x /usr/bin/awk ]]; then export PATH=\"\$(echo \"\$PATH\" | /usr/bin/awk 'BEGIN { RS=\":\"; } { sub(sprintf(\"%c$\", 10), \"\"); if (A[\$0]) {} else { A[\$0]=1; printf(((NR==1) ?\"\" : \":\") \$0) }}')\"; fi"

  # Modify the prompt too. IMO we just want to highlight that we are in a pixi
  # environment we don't need to tell them the folder basename again.
  #
  # UPDATE: Ah it's the project name from pixi.toml that is shown here & in my
  # case it just so happens to be the same as the basename & so for me it just
  # looked like duplicated info in my shell.
  #
  # Still wouldn't this be the case most of the time? Who would have a dirctory
  # name different to the project name? Anyway I'm going to leave this little
  # modification in place for now.
  PIXI_INIT="$(echo "${PIXI_INIT}" | sed '/export PIXI_PROMPT=.*/d')"
  PIXI_INIT="$(echo "${PIXI_INIT}" | sed '/export PS1=.*/d')"
  PIXI_INIT="${PIXI_INIT}\nexport PIXI_PROMPT=\"pixi\""
  PIXI_INIT="${PIXI_INIT}\nexport PS1=\"(\${PIXI_PROMPT}) \$PS1\""

  # Write the init script to all the various profiles
  # I actually sort of thought that writting it only to .profile would work for all cases???
  echo "${PIXI_INIT}" >>"${_REMOTE_USER_HOME}/.profile"
  echo "${PIXI_INIT}" >>"${_REMOTE_USER_HOME}/.bashrc"
  echo "${PIXI_INIT}" >>"${_REMOTE_USER_HOME}/.zshrc"

  # Move the pixi workspace back to /pixi where we will symlink to it on container start
  cd "$prevDir"
  rm -rf /pixi
  mv "${PIXI_WORKSPACE_DIR}" /pixi
  chown "${_REMOTE_USER}" /pixi
  clean_tmux
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
