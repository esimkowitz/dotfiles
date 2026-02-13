#!/usr/bin/env bash
# Fish install logic adapted from https://github.com/meaningful-ooo/devcontainer-features (MIT)

set -e

source /etc/os-release

cleanup() {
  case "${ID}" in
    debian|ubuntu)
      rm -rf /var/lib/apt/lists/*
    ;;
  esac
}

# Clean up
cleanup

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

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

# Checks if packages are installed and installs them if not
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

# Install dependencies if missing
check_packages curl ca-certificates

# Install fish shell
echo "Installing fish shell..."

case "${ID}" in
  debian|ubuntu)
    if [ "${ID}" = "ubuntu" ]; then
      echo "deb https://ppa.launchpadcontent.net/fish-shell/release-4/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/shells:fish:release:4.list
      curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x88421e703edc7af54967ded473c9fcc9e2bb48da" | tee -a /etc/apt/trusted.gpg.d/shells_fish_release_4.asc > /dev/null
    elif [ "${ID}" = "debian" ]; then
      echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${VERSION_ID}/ /" | tee /etc/apt/sources.list.d/shells:fish:release:4.list
      curl -fsSL "https://download.opensuse.org/repositories/shells:fish:release:4/Debian_${VERSION_ID}/Release.key" | tee /etc/apt/trusted.gpg.d/shells_fish_release_4.asc > /dev/null
    fi
    apt-get update -y
    apt-get -y install --no-install-recommends fish
  ;;
  alpine)
    apk add --no-cache fish
  ;;
esac

fish -v

# Clean up
cleanup

# Install Starship
echo "Installing Starship prompt..."
curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Set up Fish config
FISH_CONFIG_DIR="${_REMOTE_USER_HOME}/.config/fish"
mkdir -p "$FISH_CONFIG_DIR"

# Substitute greeting option and copy config
GREETING="${FISHGREETING:-"Glub glub! 🐟 🐠"}"
sed "s|{{FISH_GREETING}}|${GREETING}|g" "$(dirname "$0")/config.fish" > "$FISH_CONFIG_DIR/config.fish"

# Set ownership
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${_REMOTE_USER_HOME}/.config"

# Install onCreate script for persistent fish data
FEATURE_DIR="/usr/local/share/fish-starship"
mkdir -p "$FEATURE_DIR"
cp "$(dirname "$0")/onCreate.sh" "$FEATURE_DIR/onCreate.sh"
chmod +x "$FEATURE_DIR/onCreate.sh"

echo "Fish shell and Starship prompt installed successfully!"
