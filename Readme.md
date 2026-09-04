# Ubuntu Server Deployer

Created By Rahul Dey

## Supported Builders
- Ubuntu 24.04 (QEMU)
- Ubuntu 24.04 (SSH)

## Get Started

### Build over SSH

```bash
packer build -only=null.ssh -var 'ssh_host={server_ip}' -var 'ssh_private_key_file={private_key_file_path}' .
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
