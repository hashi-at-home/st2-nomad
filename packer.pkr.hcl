packer {
  required_plugins {
    docker = {
      version = "~> v1.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "mongodb-arm64" {
  image  = "public.ecr.aws/amazonlinux/amazonlinux:2.0.20230504.1-arm64v8"
  commit = true
  changes = [
    "LABEL org.opencontainers.image.source=https://github.com/hashi-at-home/st2-nomad",
    "LABEL org.opencontainers.image.licenses=MPL"
  ]
  run_command = [
    "-d", "-i", "-t", "--entrypoint=/bin/bash", "--name=mongodb-arm64",
    "--", "{{ .Image}}"
  ]
  // platform = "linux/arm64v8"
}

build {
  name   = "mongodb-arm64"
  sources = ["source.docker.mongodb-arm64"]
  provisioner "shell" {
        inline = [
            "uname -a",
        ]
    }
}
