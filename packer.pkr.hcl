packer {
  required_plugins {
    docker = {
      version = "~> v1.0"
      source  = "github.com/hashicorp/docker"
    }
  }
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
source "docker" "mongodb-arm64" {
  image  = "arm64v8/ubuntu:22.04"
  commit = true
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
  platform = "linux/arm64v8"
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
      "curl -fSL https://fastdl.mongodb.org/linux/mongodb-linux-aarch64-ubuntu2204-6.0.6.tgz | tar xvz --strip-components=1 -C /",
      "which mongod"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "ghcr.io/hashi-at-home/mongo-server"
      tags       = ["latest"]
    }
  }
}
