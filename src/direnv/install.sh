#!/usr/bin/env bash
set -e

source /etc/os-release

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

apt_get_update() {
  case "${ID}" in
    debian|ubuntu)
      if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
      fi
    ;;
  esac
}

check_packages() {
  case "${ID}" in
    debian|ubuntu)
      if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
      fi
    ;;
    alpine)
      if ! apk -e info "$@" >/dev/null 2>&1; then
        apk add --no-cache "$@"
      fi
    ;;
  esac
}

export DEBIAN_FRONTEND=noninteractive

VERSION="${VERSION:-"latest"}"

# Install direnv
echo "Installing direnv..."

if [ "${VERSION}" = "system" ]; then
  check_packages direnv
else
  check_packages curl ca-certificates
  curl -sfL https://direnv.net/install.sh | bash
fi

direnv version

# Configure bash hook
if [ -f /etc/bash.bashrc ]; then
  if ! grep -q 'direnv hook bash' /etc/bash.bashrc; then
    echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc
    echo "Added direnv hook to /etc/bash.bashrc"
  fi
fi

# Configure zsh hook
if [ -d /etc/zsh ]; then
  if [ ! -f /etc/zsh/zshrc ]; then
    touch /etc/zsh/zshrc
  fi
  if ! grep -q 'direnv hook zsh' /etc/zsh/zshrc; then
    echo 'eval "$(direnv hook zsh)"' >> /etc/zsh/zshrc
    echo "Added direnv hook to /etc/zsh/zshrc"
  fi
fi

# Configure fish hook
FISH_CONFIG="${_REMOTE_USER_HOME}/.config/fish/config.fish"
if [ -f "$FISH_CONFIG" ]; then
  if ! grep -q 'direnv hook fish' "$FISH_CONFIG"; then
    # Insert direnv hook inside the "if status is-interactive" block
    sed -i '/^if status is-interactive/a\    direnv hook fish | source' "$FISH_CONFIG"
    echo "Added direnv hook to $FISH_CONFIG"
  fi
fi

# Deploy direnv.toml for the remote user.
# `load_dotenv` is a direnv.toml config KEY, not a shell command — putting it in
# direnvrc (which is sourced as a shell script) only yields
# "load_dotenv: command not found" and never loads .env files. The correct
# mechanism is `load_dotenv = true` under [global] in direnv.toml.
DIRENV_CONFIG_DIR="${_REMOTE_USER_HOME}/.config/direnv"
mkdir -p "$DIRENV_CONFIG_DIR"
cp "$(dirname "$0")/direnv.toml" "$DIRENV_CONFIG_DIR/direnv.toml"
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "$DIRENV_CONFIG_DIR"

echo "direnv installed and configured successfully!"
