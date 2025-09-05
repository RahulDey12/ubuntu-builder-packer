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
