#!/bin/bash
set -e

echo "[DOCKER] Removing conflicting packages (ignore errors if not present)..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get -y remove "$pkg" || true
done

echo "[DOCKER] Update base packages..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "[DOCKER] Prepare keyring..."
sudo install -m 0755 -d /etc/apt/keyrings

# Use dearmored key (recommended)
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Determine codename (e.g., jammy, noble)
UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"

echo "[DOCKER] Add Docker apt repository for ${UBUNTU_CODENAME}..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[DOCKER] Install Docker Engine & plugins..."
sudo apt-get update -y
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "[DOCKER] Enable & start services..."
sudo systemctl enable docker
sudo systemctl restart docker

# Works for both direct sudo and root shells in Packer
DOCKER_USER="${SUDO_USER:-${USER:-}}"
if [ -n "${DOCKER_USER}" ] && id -u "${DOCKER_USER}" >/dev/null 2>&1; then
  echo "[DOCKER] Adding user '${DOCKER_USER}' to docker group..."
  sudo usermod -aG docker "${DOCKER_USER}" || true
fi

echo "[DOCKER] Versions:"
docker --version || true
docker compose version || true

echo "[DOCKER] Done."
