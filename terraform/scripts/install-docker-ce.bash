#!/bin/bash

if [ "$#" -ge 1 ]; then
  DOCKER_VERSION=$1
else
  DOCKER_VERSION=""
fi

sudo apt-get update

sudo apt-get install -y           \
  apt-transport-https        \
  ca-certificates            \
  curl                       \
  gnupg-agent                \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository                                            \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs)                                         \
  stable"

sudo apt-get update

DOCKER_PKG_ID=`apt-cache madison docker-ce | grep "${DOCKER_VERSION}" | head -1 | awk '{ print $3 }'`

sudo apt-get install -y               \
  docker-ce=${DOCKER_PKG_ID}     \
  docker-ce-cli=${DOCKER_PKG_ID} \
  containerd.io

sudo apt-mark hold docker-ce docker-ce-cli containerd.io