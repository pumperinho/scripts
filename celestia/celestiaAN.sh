#!/bin/bash

# update and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y
sudo apt install --fix-broken -y &>/dev/null
sudo apt install nano mc wget -y &>/dev/null

# Go
cd $HOME
ver="1.17.2"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
sleep 3
source $HOME/.bash_profile
go version

# Build App
cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
make install
celestia-appd version --long

# Network
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git


# Variables
if [ -z ${CELESTIA_NODENAME} ]; then
        read -p "CELESTIA_NODENAME: " CELESTIA_NODENAME
        echo 'export CELESTIA_NODENAME='$CELESTIA_NODENAME >> $HOME/.bash_profile
fi

if [ -z ${CELESTIA_WALLET} ]; then
        read -p "CELESTIA_WALLET: " CELESTIA_WALLET
        echo 'export CELESTIA_WALLET='$CELESTIA_WALLET >> $HOME/.bash_profile
fi

if [ -z {CELESTIA_CHAIN} ]; then
        CELESTIA_CHAIN="devnet-2"
        echo 'export CELESTIA_CHAIN='$CELESTIA_CHAIN >> $HOME/.bash_profile

fi
source $HOME/.bash_profile

# Init
celestia-appd init $CELESTIA_NODENAME --chain-id $CELESTIA_CHAIN

# copy devnet-2 genesis
cp $HOME/networks/devnet-2/genesis.json $HOME/.celestia-app/config/

# update seeds and peers
SEEDS="74c0c793db07edd9b9ec17b076cea1a02dca511f@46.101.28.34:26656"
PEERS="34d4bfec8998a8fac6393a14c5ae151cf6a5762f@194.163.191.41:26656"

sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.celestia-app/config/config.toml

# add external
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address = \"\"/external_address = \"$external_address:26656\"/" $HOME/.celestia-app/config/config.toml

# open rpc
sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:26657"#g' $HOME/.celestia-app/config/config.toml

# set proper defaults
sed -i 's/timeout_commit = "5s"/timeout_commit = "15s"/g' $HOME/.celestia-app/config/config.toml
sed -i 's/index_all_keys = false/index_all_keys = true/g' $HOME/.celestia-app/config/config.toml

# open rest api
sed -i '/\[api\]/{:a;n;/enabled/s/false/true/;Ta};/\[api\]/{:a;n;/enable/s/false/true/;Ta;}' $HOME/.celestia-app/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="5000"
pruning_interval="10"

sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.celestia-app/config/app.toml

# reset state
celestia-appd unsafe-reset-all

# Config client
celestia-appd config chain-id $CELESTIA_CHAIN
celestia-appd config keyring-backend test

# create service
sudo tee /etc/systemd/system/celestia-appd.service > /dev/null <<EOF
[Unit]
  Description=celestia-appd Cosmos daemon
  After=network-online.target
[Service]
  User=$USER
  ExecStart=$(which celestia-appd) start
  Restart=on-failure
  RestartSec=3
  LimitNOFILE=4096
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl enable celestia-appd
sudo systemctl daemon-reload
sudo systemctl restart celestia-appd && journalctl -u celestia-appd.service -f

# Press CTRL+C to interrupt logs output