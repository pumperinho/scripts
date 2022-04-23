#!/bin/bash

cd $HOME
wget https://raw.githubusercontent.com/pumperinho/scripts/main/logo.sh
chmod +x logo.sh
./logo.sh

cd $HOME 

wget -O go1.17.1.linux-amd64.tar.gz https://golang.org/dl/go1.17.linux-amd64.tar.gz 

rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz && rm go1.17.1.linux-amd64.tar.gz 

echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile 

echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile 

echo 'export GO111MODULE=on' >> $HOME/.bash_profile

echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile

sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

git clone https://github.com/defund-labs/defund
cd $HOME/defund
make install

DEFUND_CHAIN="defund-private-1"


DEFUND_CHAIN="defund-private-1"
DEFUND_MONIKER="YOUR_MONIKER_NAME"
DEFUND_WALLET="YOUR_WALLET_NAME"

read -p "DEFUND_MONIKER: " DEFUND_MONIKER
read -p "DEFUND_WALLET: " DEFUND_WALLET

echo 'export DEFUND_CHAIN='${DEFUND_CHAIN} >> $HOME/.bash_profile
echo 'export DEFUND_MONIKER='${DEFUND_MONIKER} >> $HOME/.bash_profile
echo 'export DEFUND_WALLET='${DEFUND_WALLET} >> $HOME/.bash_profile
source $HOME/.bash_profile

defundd init $DEFUND_MONIKER --chain-id=$DEFUND_CHAIN

seeds="1b3e596531dd8f36363b13339beed2364900e4c6@104.131.41.157:26656" peers="111ba4e5ae97d5f294294ea6ca03c17506465ec5@208.68.39.221:26656,26c42b6c3e8940c5433a5601464c4b370ab32cb4@139.162.146.250:26656" 

sed -i "s/^seeds *=.*/seeds = \"$seeds\"/;" $HOME/.defund/config/config.toml

sed -i "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/;" $HOME/.defund/config/config.toml

wget -O $HOME/.defund/config/genesis.json https://raw.githubusercontent.com/schnetzlerjoe/defund/main/testnet/private/genesis.json 

defundd tendermint unsafe-reset-all --home $HOME/.defund

defundd config chain-id $DEFUND_CHAIN
defundd config keyring-backend test

cd $HOME

archwayd keys add $ARCHWAY_WALLET &> "mnemonic.txt"

tee $HOME/defund.service > /dev/null <<EOF
[Unit]
Description=Defund
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which defundd) start
Restart=on-failure
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

DEFUND_ADDR=$(defundd keys show $DEFUND_WALLET -a)

echo 'export DEFUND_ADDR='${DEFUND_ADDR} >> $HOME/.bash_profile

source $HOME/.bash_profile

sudo mv $HOME/defund.service /etc/systemd/system/

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable defund
sudo systemctl restart defund

