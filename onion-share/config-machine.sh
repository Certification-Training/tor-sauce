#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [[ -d /var/lib/cloud/instance/ ]]; then
  until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
    sleep 1
  done
fi

sudo add-apt-repository ppa:micahflee/ppa
sudo apt-get update

sudo apt-get install --assume-yes onionshare