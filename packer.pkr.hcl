packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }

    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

variable "ssh_host" {
  type = string
  default  = null
  nullable = true
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_private_key_file" {
  type    = string
  default = ""
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = ""
}

source "qemu" "ubuntu-24" {
  iso_url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  iso_checksum     = "sha256:834af9cd766d1fd86eca156db7dff34c3713fbbc7f5507a3269be2a72d2d1820"
  ssh_username     = "ubuntu"
  ssh_password     = "adminadmin"
  communicator     = "ssh"
  headless         = true
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  disk_size        = "10G"
  format           = "raw"
  ssh_timeout      = "20m"
  disk_image       = true 
  boot_wait        = "5s"
  shutdown_command = "sudo shutdown -P now"

  cd_files         = ["./cd-rom/user-data", "./cd-rom/meta-data"]
  cd_label         = "cidata"
  qemuargs = [
    ["-m", "2048M"],
  ]
}

source "null" "ssh" {
  communicator  = "ssh"
  ssh_host      = var.ssh_host
  ssh_port      = var.ssh_port
  ssh_username  = var.ssh_username

  # use key if given, else password
  ssh_private_key_file = length(var.ssh_private_key_file) > 0 ? var.ssh_private_key_file : null
  ssh_password         = length(var.ssh_password) > 0 ? var.ssh_password : null

  ssh_timeout   = "10m"
}

build {
  sources = ["source.qemu.ubuntu-24", "source.null.ssh"]

  provisioner "file" {
    source      = "files/sshd_config.conf"
    destination = "/tmp/secure_sshd_config.conf"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "SSH_PORT=${var.ssh_port}",
      "ENABLE_PASSWORD_AUTH=${length(var.ssh_password) > 0 ? "true" : "false"}",
      "ENABLE_ROOT_LOGIN=${var.ssh_username == "root" ? "true" : "false"}",
    ]
    scripts = [
      "scripts/setup.sh",
      "scripts/security.sh",
      "scripts/install_docker.sh",
    ]
  }
}
