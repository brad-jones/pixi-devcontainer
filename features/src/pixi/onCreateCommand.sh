#!/bin/bash
set -e
shopt -s dotglob

# onCreateCommand: A command to run when creating the container.
# This command is run after "initializeCommand" and before "updateContentCommand".

# In some conditions (ie: using the devcontainer cli as opposed to say VsCode)
# the environmenht variable $USER is not set so we will set it here if need be.
if [ -z "$USER" ]; then
  export USER
  USER="$(whoami)"
fi

# Mounts are created by root so this is our best effort to set
# permissions for the current user so they can write to the volume.
if [ "$USER" != "root" ]; then
  if command -v sudo >/dev/null; then
    sudo chown "${USER}:${USER}" ./.pixi
  else
    chown "${USER}:${USER}" ./.pixi
  fi
fi

# Now symlink the prebuilt pixi dir to the workspace.
# We can't symlink the entire pixi dir because it's the volume mount point.
# And the reason for creating the mount is so that we don't leave invalid
# symlinks behind on the host system.
if [ -f /pixi/.pixi/prefix ]; then
  rm -rf ./.pixi/*
  for fP in /pixi/.pixi/*; do
    fN="$(basename "$fP")"
    ln -s "/pixi/.pixi/$fN" "./.pixi/$fN"
  done
fi
