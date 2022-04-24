#!/bin/bash

cd $HOME
wget https://raw.githubusercontent.com/pumperinho/scripts/main/logo.sh
chmod +x logo.sh
./logo.sh

# update
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

sudo apt install -y uidmap dbus-user-session

# download binary
git clone https://github.com/defund-labs/defund
cd $HOME/defund
make install

# set vars
DEFUND_CHAIN="defund-private-1"
read -p "DEFUND_MONIKER: " DEFUND_MONIKER
read -p "DEFUND_WALLET: " DEFUND_WALLET

echo 'export DEFUND_CHAIN='${DEFUND_CHAIN} >> $HOME/.bash_profile
echo 'export DEFUND_MONIKER='${DEFUND_MONIKER} >> $HOME/.bash_profile
echo 'export DEFUND_WALLET='${DEFUND_WALLET} >> $HOME/.bash_profile
source $HOME/.bash_profile

# init
defundd init $DEFUND_MONIKER --chain-id=$DEFUND_CHAIN

# config
seeds="1b3e596531dd8f36363b13339beed2364900e4c6@104.131.41.157:26656" peers="111ba4e5ae97d5f294294ea6ca03c17506465ec5@208.68.39.221:26656,26c42b6c3e8940c5433a5601464c4b370ab32cb4@139.162.146.250:26656" 

sed -i "s/^seeds *=.*/seeds = \"$seeds\"/;" $HOME/.defund/config/config.toml

sed -i "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/;" $HOME/.defund/config/config.toml "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.archway/config/config.toml

pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="1000"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.defund/config/app.toml
peers="fd6a6535a5c1d87756b8065ec9d4e28057945d43@65.108.78.107:26652" \
&& sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.defund/config/config.toml


# get genesis.json
wget https://raw.githubusercontent.com/defund-labs/defund/163e2669b6870aa26b73d843312b22c9948b29c6/testnet/private/genesis.json

defundd tendermint unsafe-reset-all --home $HOME/.defund

# reset
defundd config chain-id ${DEFUND_CHAIN}
defundd config keyring-backend test

# create keys

cd $HOME

defundd keys add ${DEFUND_WALLET} | tee -a "mnemonic.txt"

# SAVE MNEMONIC FROM OUTPUT !!



# save addr and valoper ======================================== (OPTIONAL) =================================================
DEFUND_ADDR=$(defundd keys show $DEFUND_WALLET -a)

echo 'export DEFUND_ADDR='${DEFUND_ADDR} >> $HOME/.bash_profile

source $HOME/.bash_profile

DEFUND_VALOPER=$(defundd  keys show $DEFUND_WALLET --bech val -a)

echo 'export DEFUND_VALOPER='${DEFUND_VALOPER} >> $HOME/.bash_profile
source $HOME/.bash_profile
# ============================================================ (OPTIONAL) ================================================



# create service
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

sudo mv $HOME/defund.service /etc/systemd/system/

# start service
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable defund
sudo systemctl restart defund