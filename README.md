[![.github/workflows/release.yml](https://github.com/hashi-at-home/st2-nomad/actions/workflows/release.yml/badge.svg)](https://github.com/hashi-at-home/st2-nomad/actions/workflows/release.yml)

# st2-nomad

Deploy StackStorm on Nomad.
This is created as a use case for [hashiatho.me](https://hashiatho.me), so relevant constraints apply:

1. Small footprint
1. ARM images for Raspberry Pis


## Backing services

Stackstorm requires two backing services:

1. MongoDB
1. RabbitMQ

Since there is no mongoDB server image for ARM64, we include a packer template for building this.
It is published as a package in this repo's container registry.
