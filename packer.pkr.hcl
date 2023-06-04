packer {
  required_plugins {
    docker = {
      version = "~> v1.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "reg_password" {
  default   = env("GITHUB_TOKEN")
  sensitive = true
}

variable "reg_username" {
  default   = env("REG_USERNAME")
  sensitive = false
}

variable "apt_dependencies" {
  type        = list(string)
  description = "List of OS level dependencies"
  default = [
    "curl",
    "libcurl4",
    "libgssapi-krb5-2",
    "libldap-2.5-0",
    "libwrap0",
    "libsasl2-2",
    "libsasl2-modules",
    "libsasl2-modules-gssapi-mit",
    "openssl",
    "liblzma5",
    "python3",
    "snmp"
  ]
}

variable "mongo_version" {
  type        = string
  description = "Version of the mongo community server to use"
  default     = "6.0.6"
}

source "docker" "mongodb-arm64" {
  image  = "arm64v8/ubuntu:22.04"
  commit = true
  pull   = true
  changes = [
    "LABEL org.opencontainers.image.source=https://github.com/hashi-at-home/st2-nomad",
    "LABEL org.opencontainers.image.licenses=MPL",
    "ENTRYPOINT [\"python3\", \"/usr/local/bin/docker-entrypoint.py\"]",
    "CMD mongod",
    "VOLUME /data/configdb",
    "VOLUME /data/db",
    "EXPOSE 27017",
    "ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "ENV HOME /data/db"
  ]
  run_command = [
    "-d", "-i", "-t", "--entrypoint=/bin/bash", "--name=mongodb-arm64",
    "--", "{{ .Image}}"
  ]
  platform = "linux/arm64/v8"
}

build {
  name    = "mongodb-arm64"
  sources = ["source.docker.mongodb-arm64"]
  provisioner "shell" {
    inline = [
      "uname -a",
      "apt-get update",
      "apt-get install -yq ${join(" ", var.apt_dependencies)}"
    ]
  }

  provisioner "shell" {
    inline = [
      "curl -fSL https://fastdl.mongodb.org/linux/mongodb-linux-aarch64-ubuntu2204-${var.mongo_version}.tgz | tar xvz --strip-components=1 -C /",
      "which mongod"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "ghcr.io/hashi-at-home/st2-nomad/mongo-server"
      tags       = ["mongo-v${var.mongo_version}-latest"]
    }
    post-processor "docker-push" {
      login          = true
      login_username = var.reg_username
      login_password = var.reg_password
      login_server   = "https://ghcr.io"
    }
  }
}
