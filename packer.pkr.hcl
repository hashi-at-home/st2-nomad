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
    "ca-certificates",
    "curl",
    "gnupg",
    "jq",
    "libcurl4",
    "libcurl4-openssl-dev",
    "libgssapi-krb5-2",
    "libldap-2.5-0",
    "libwrap0",
    "libsasl2-2",
    "libsasl2-modules",
    "libsasl2-modules-gssapi-mit",
    "libssl-dev",
    "liblzma5",
    "liblzma-dev",
    "numactl",
    "openssl",
    "procps",
    "python3",
    "python3-virtualenv",
    "snmp",
    "tzdata"
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
    "ENTRYPOINT [\"mongod\", \"--dbpath /data/db/\"]",
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
      "DEBIAN_FRONTEND=noninteractive apt-get install -yq ${join(" ", var.apt_dependencies)}"
    ]
  }

  # Prepare environment
  provisioner "shell" {
    inline = [
      "groupadd --gid 999 --system mongodb",
      "useradd --uid 999 --system --gid mongodb --home-dir /data/db mongodb",
      "mkdir -vp /data/db /data/configdb /build",
      "chown -R mongodb:mongodb /data/db /data/configdb /build"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "PREFIX=/usr/local/",
      "DESTDIR=/opt/mongo"
    ]
    inline = [
      "curl -fSL https://fastdl.mongodb.org/src/mongodb-src-r${var.mongo_version}.tar.gz | tar xz --strip-components=1 -C /build",
      "cd /build",
      "virtualenv mongodb ; ls -lht mongodb",
      ". mongodb/bin/activate ; pip install -r ./etc/pip/dev-requirements.txt",
      ". mongodb/bin/activate ; buildscripts/scons.py install-mongod install-mongo install-mongos --enable-http-client=on --ssl=on --wiredtiger=on -j2",
      ". mongodb/bin/activate ; buildscripts/scons.py install",
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
