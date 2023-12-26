#!/bin/sh
set -e

build_url() {
  echo "https://github.com/prefix-dev/pixi/releases/${VERSION:-latest}/download/pixi-x86_64-unknown-linux-musl.tar.gz"
}

install_pixi_wrapper() {
  cat <<-"EOF" >>/usr/bin/pixi
#!/usr/bin/env bash
export XDG_CACHE_HOME="/pixi-cache"
exec /opt/pixi "$@"
EOF
  chmod +x /usr/bin/pixi
}

install_pixi_onCreateCommand() {
  cat <<-"EOF" >>/usr/local/share/pixi-onCreateCommand.sh
#!/bin/sh
set -e

if [ -n "$USER" ] && [ "$USER" != "root" ]; then
  if command -v sudo >/dev/null; then
    sudo chown -R ${USER} ./.pixi /pixi-cache
  else
    chown -R ${USER} ./.pixi /pixi-cache
  fi
fi

echo "export PATH=\"\$HOME/.pixi/bin:\$PATH\"" >> "$HOME/.bashrc"
echo "export PATH=\"$PWD/.pixi/env/bin:\$PATH\"" >> "$HOME/.bashrc"
echo "export PATH=\"\$HOME/.pixi/bin:\$PATH\"" >> "$HOME/.zshrc"
echo "export PATH=\"$PWD/.pixi/env/bin:\$PATH\"" >> "$HOME/.zshrc"
echo "export PATH=\"\$HOME/.pixi/bin:\$PATH\"" >> "$HOME/.profile"
echo "export PATH=\"$PWD/.pixi/env/bin:\$PATH\"" >> "$HOME/.profile"
EOF

  chmod +x /usr/local/share/pixi-onCreateCommand.sh
}

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

install_pixi() {
  mkdir -p /tmp/pixi
  curl -L "$(build_url)" -o /tmp/pixi.tar.gz
  tar -xf /tmp/pixi.tar.gz -C /tmp/pixi
  chmod +x /tmp/pixi/pixi
  mv /tmp/pixi/pixi /opt/pixi
  rm -rf /tmp/pixi /tmp/pixi.tar.gz
}

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
