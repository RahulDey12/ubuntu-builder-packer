#!/bin/bash
set -e

echo "[SETUP] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[SETUP] Installing common tools..."
sudo apt-get install -y \
  curl \
  wget \
  git \
  unzip \
  htop \
  ufw \
  build-essential \
  software-properties-common

echo "[SETUP] Enabling SSH service..."
sudo systemctl enable ssh
