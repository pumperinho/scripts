#!/bin/bash

# update
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y

# GO
cd $HOME
ver="1.17.2"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version

# Make Variable
CELESTIA_CHAIN="devnet-2"
read -p 'input CELESTIA_NODENAME: ' CELESTIA_NODENAME
read -p 'input CELESTIA_WALLET: ' CELESTIA_NODENAME
source $HOME/.bash_profile

# init app
cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
make install
celestia-appd init $CELESTIA_NODENAME --chain-id $CELESTIA_CHAIN

# Download network
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git
cp $HOME/networks/devnet-2/genesis.json $HOME/.celestia-app/config/
SEEDS="74c0c793db07edd9b9ec17b076cea1a02dca511f@46.101.28.34:26656"
PEERS="34d4bfec8998a8fac6393a14c5ae151cf6a5762f@194.163.191.41:26656"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.celestia-app/config/config.toml
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address = \"\"/external_address = \"$external_address:26656\"/" $HOME/.celestia-app/config/config.toml
sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:26657"#g' $HOME/.celestia-app/config/config.toml
sed -i 's/timeout_commit = "5s"/timeout_commit = "15s"/g' $HOME/.celestia-app/config/config.toml
sed -i 's/index_all_keys = false/index_all_keys = true/g' $HOME/.celestia-app/config/config.toml
sed -i '/\[api\]/{:a;n;/enabled/s/false/true/;Ta};/\[api\]/{:a;n;/enable/s/false/true/;Ta;}' $HOME/.celestia-app/config/app.toml
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="5000"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.celestia-app/config/app.toml
celestia-appd unsafe-reset-all
wget -O $HOME/.celestia-app/config/addrbook.json "https://raw.githubusercontent.com/maxzonder/celestia/main/addrbook.json"


celestia-appd config chain-id $CELESTIA_CHAIN
celestia-appd config keyring-backend test

# Systemd File
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-appd.service
[Unit]
Description=celestia-appd Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/celestia-appd start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable celestia-appd
sudo systemctl daemon-reload
sudo systemctl restart celestia-appd && journalctl -u celestia-appd.service -f

CELESTIA_NODENAME=$CELESTIA_NODENAME
CELESTIA_WALLET=$CELESTIA_WALLET
echo 'export CELESTIA_CHAIN='$CELESTIA_CHAIN >> $HOME/.bash_profile
echo 'export CELESTIA_NODENAME='${CELESTIA_NODENAME} >> $HOME/.bash_profile
echo 'export CELESTIA_WALLET='${CELESTIA_WALLET} >> $HOME/.bash_profile
source $HOME/.bash_profile