# Ubuntu Server Deployer

Created By Rahul Dey

## Supported Builders
- Ubuntu 24.04 (QEMU)
- Ubuntu 24.04 (SSH)

## Prerequisites

- **The build user must have passwordless (`NOPASSWD`) sudo.** `setup.sh`,
  `security.sh`, and `install_docker.sh` all run many `sudo` commands
  non-interactively — there's no TTY for a sudo password prompt, so the
  build will hang/fail if one is required.
  - **QEMU build**: handled automatically — cloud-init (`cd-rom/user-data`)
    creates the `ubuntu` user with `sudo: ALL=(ALL) NOPASSWD:ALL`.
  - **SSH build (`null.ssh`)**: Packer connects to an *existing* server, so
    it does not create or configure the user for you — make sure the
    `ssh_username` you pass already has `NOPASSWD` sudo configured on that
    server before running the build.

## Get Started

### Build over SSH

```bash
packer build -only=null.ssh -var 'ssh_host={server_ip}' -var 'ssh_private_key_file={private_key_file_path}' .
```

Optional vars for non-default setups (see [Security Heads-Up](#️-security-heads-up)):

```bash
packer build -only=null.ssh \
  -var 'ssh_host={server_ip}' \
  -var 'ssh_username={username}' \
  -var 'ssh_port={port}' \
  -var 'ssh_private_key_file={private_key_file_path}' \
  -var 'ssh_password={password}' \
  .
```

### Build on QEMU

```bash
packer build -only=qemu.ubuntu-24 .
```

## ⚠️ Security Heads-Up

- `ssh_port`: UFW opens whatever port you pass here. If you build against an
  existing server (`null.ssh`) on a non-default SSH port, that port is what
  gets allowed through the firewall (instead of always opening 22).
- `ssh_password`: if you pass a password (instead of only a private key),
  **password authentication is left enabled** on the target host
  (`AuthenticationMethods any`, `PasswordAuthentication yes`) so the build
  can complete. By default (key-only builds) password auth stays disabled
  and only `publickey` auth is accepted. Only set `ssh_password` on hosts
  where you're comfortable with password login being allowed after the
  build finishes — rotate/disable it afterwards if you don't need it
  long-term.
- `ssh_username`: if set to `root`, root login is left enabled
  (`PermitRootLogin yes`) instead of the default `no`. **This is not
  recommended** — only use a `root` build user when you specifically
  need it, and prefer a non-root `ssh_username` otherwise.
