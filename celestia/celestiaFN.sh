#!/bin/bash

# update and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y
sudo apt install --fix-broken -y &>/dev/null
sudo apt install nano mc wget -y &>/dev/null

cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node
git checkout v0.1.1
make install

celestia version
# Semantic version: v0.1.1

# set proper port here if not default!
TRUSTED_SERVER="http://localhost:26657"

# start full node from current block
TRUSTED_HASH=$(curl -s $TRUSTED_SERVER/status | jq -r .result.sync_info.latest_block_hash)

# check
echo $TRUSTED_HASH
# output example 4632277C441CA6155C4374AC56048CF4CFE3CBB2476E07A548644435980D5E17

# IF OUTPUT OK! - DO NEXT ->

# save vars
echo 'export TRUSTED_SERVER='${TRUSTED_SERVER} >> $HOME/.bash_profile
echo 'export TRUSTED_HASH='${TRUSTED_HASH} >> $HOME/.bash_profile
source $HOME/.bash_profile

# init
celestia full init --core.remote $TRUSTED_SERVER --headers.trusted-hash $TRUSTED_HASH

# config
sed -i.bak -e 's/PeerExchange = false/PeerExchange = true/g' $HOME/.celestia-full/config.toml

sudo tee /etc/systemd/system/celestia-full.service > /dev/null <<EOF
[Unit]
  Description=celestia-full node
  After=network-online.target
[Service]
  User=$USER
  ExecStart=$(which celestia) full start
  Restart=on-failure
  RestartSec=10
  LimitNOFILE=4096
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl enable celestia-full
sudo systemctl daemon-reload


# start and save multiaddress
sudo systemctl restart celestia-full && sleep 10 && journalctl -u celestia-full -o cat -n 10000 --no-pager | grep -m 1 "*  /ip4/" > $HOME/multiaddress.txt

# check result
cat $HOME/multiaddress.txt

# output example
# *  /ip4/45.134.226.46/tcp/2121/p2p/12D3KooWEnB91geSJKgTMGHs8dLs9XHUYy19Ja92vqGSdAw6hngw

# IF OUTPUT OK! - DO NEXT ->

# save var
FULL_NODE_IP=$(cat $HOME/multiaddress.txt | sed -r 's/^.{3}//')
echo 'export FULL_NODE_IP='${FULL_NODE_IP} >> $HOME/.bash_profile
source $HOME/.bash_profile

# check logs (CTRL+C to interrupt)
journalctl -u celestia-full -o cat -f