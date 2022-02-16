#!/bin/bash

# update and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y
sudo apt install --fix-broken -y &>/dev/null
sudo apt install nano mc wget -y &>/dev/null

# Donloar
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node
git checkout v0.1.1
make install
celestia version

