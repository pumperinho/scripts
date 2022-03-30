#!/bin/bash
# update
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

sudo apt install -y uidmap dbus-user-session

# download binary
cd $HOME
mkdir archway && cd archway
wget "https://github.com/Northa/archway_bin/releases/download/v0.0.3/archwayd"

sha256sum archwayd
# f9d35c829ed84d427a3e923ba93f2bac400a17ca1d38f7964156f24def891d08  archwayd

chmod +x archwayd
sudo mv archwayd /usr/local/bin/

# set vars
ARCHWAY_CHAIN="augusta-1"
read -p "YOUR_MONIKER_NAME: " ARCHWAY_MONIKER
read -p "YOUR_WALLET_NAME: " ARCHWAY_WALLET

echo 'export ARCHWAY_CHAIN='${ARCHWAY_CHAIN} >> $HOME/.bash_profile
echo 'export ARCHWAY_MONIKER='${ARCHWAY_MONIKER} >> $HOME/.bash_profile
echo 'export ARCHWAY_WALLET='${ARCHWAY_WALLET} >> $HOME/.bash_profile
source $HOME/.bash_profile

# init
archwayd init ${ARCHWAY_MONIKER} --chain-id $ARCHWAY_CHAIN

# config
archwayd config chain-id $ARCHWAY_CHAIN

seeds="2f234549828b18cf5e991cc884707eb65e503bb2@34.74.129.75:31076,c8890bcde31c2959a8aeda172189ec717fef0b2b@95.216.197.14:26656"
PEERS="1f6dd298271684729d0a88402b1265e2ae8b7e7b@162.55.172.244:26656"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.archway/config/config.toml

# add external (if dont use sentry), port is default
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address = \"\"/external_address = \"$external_address:26656\"/" $HOME/.archway/config/config.toml

sed -i.bak -e "s/prometheus = false/prometheus = true/" $HOME/.archway/config/config.toml

# get genesis.json
wget -O $HOME/.archway/config/genesis.json "https://github.com/maxzonder/archway/raw/main/genesis.json"

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="5000"
pruning_interval="10"

sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.archway/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.archway/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.archway/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.archway/config/app.toml

# reset
archwayd unsafe-reset-all

archwayd config chain-id $ARCHWAY_CHAIN
archwayd config keyring-backend test
# create keys

cd $HOME

archwayd keys add $ARCHWAY_WALLET | tee "mnemonic.txt"

# SAVE MNEMONIC FROM OUTPUT !!



# save addr and valoper ======================================== (OPTIONAL) =================================================
ARCHWAY_ADDR=$(archwayd keys show $ARCHWAY_WALLET -a)

echo $ARCHWAY_ADDR

ARCHWAY_VALOPER=$(archwayd keys show $ARCHWAY_WALLET --bech val -a)

# check
echo $ARCHWAY_VALOPER

# save
echo 'export ARCHWAY_ADDR='${ARCHWAY_ADDR} >> $HOME/.bash_profile
echo 'export ARCHWAY_VALOPER='${ARCHWAY_VALOPER} >> $HOME/.bash_profile
source $HOME/.bash_profile
# ============================================================ (OPTIONAL) ================================================



# create service
tee $HOME/archwayd.service > /dev/null <<EOF
[Unit]
Description=ARCHWAY
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which archwayd) start --x-crisis-skip-assert-invariants
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/archwayd.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable archwayd
sudo systemctl restart archwayd && journalctl -u archwayd -f -o cat
