#!/bin/bash
cd $HOME
wget https://raw.githubusercontent.com/pumperinho/scripts/main/logo.sh
chmod +x logo.sh
./logo.sh
rm logo.sh

# update
sudo apt update && sudo apt upgrade -y

sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

sudo apt install -y uidmap dbus-user-session

# GO
sudo apt update  
sudo apt install build-essential jq wget git -y
wget https://dl.google.com/go/go1.17.1.linux-amd64.tar.gz
tar -xvf go1.17.1.linux-amd64.tar.gz
sudo mv go /usr/local

GOPATH=$HOME/go
GOROOT=/usr/local/go
GOBIN=$GOPATH/bin
PATH=$PATH:/usr/local/go/bin:$GOBIN

echo "" >> ~/.bashrc
echo 'export GOPATH='${GOPATH} >> ~/.bashrc
echo 'export GOROOT='${GOROOT} >> ~/.bashrc
echo 'export GOBIN='${GOBIN} >> ~/.bashrc
echo 'export PATH='${PATH} >> ~/.bashrc

source ~/.bashrc

# Starport
curl https://get.starport.network/starport! | bash
curl https://get.starport.network/starport | bash
sudo mv starport /usr/local/bin/

# Clone the Repo
git clone https://github.com/cosmic-horizon/coho.git

# Install CoHo
cd ~/coho
starport chain build

cd ~

COSMIC_CHAIN="darkenergy-1"
read -p "YOUR_MONIKER_NAME: " COSMIC_MONIKER
read -p "YOUR_WALLET_NAME: " COSMIC_WALLET

echo 'export COSMIC_CHAIN='${COSMIC_CHAIN} >> $HOME/.bash_profile
echo 'export COSMIC_MONIKER='${COSMIC_MONIKER} >> $HOME/.bash_profile
echo 'export COSMIC_WALLET='${COSMIC_WALLET} >> $HOME/.bash_profile
source $HOME/.bash_profile

cohod init ${COSMIC_MONIKER} --chain-id ${COSMIC_CHAIN}
cohod config chain-id $COSMIC_CHAIN

cohod unsafe-reset-all

cohod config chain-id ${COSMIC_CHAIN}
cohod config keyring-backend test

cohod keys add ${COSMIC_WALLET} &> mnemonic.txt