#!/bin/bash

# update if needed
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

cd $HOME
wget https://raw.githubusercontent.com/pumperinho/scripts/main/logo.sh
chmod +x logo.sh
./logo.sh

curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_ufw.sh | bash

rm -rf archway/ .archway/ .bash_profile grafanaPump.sh grafanaPump.sh.1 grafanaPump.sh.2 logo.sh.5 logo.sh.5 logo.sh.6


curl https://raw.githubusercontent.com/kuraassh/Nodes/main/Archway/install.sh > install.sh && chmod +x install.sh && ./install.sh

        wget -O $HOME/.archway/config/genesis.json https://raw.githubusercontent.com/archway-network/testnets/main/torii-1/penultimate_genesis.json