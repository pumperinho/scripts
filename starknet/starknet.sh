#!/bin/bash
sudo apt update

sudo apt full-upgrade -y

sudo apt install -y python3-pip

sudo apt install -y build-essential libssl-dev libffi-dev python3-dev

sudo apt-get install libgmp-dev -y

pip3 install fastecdsa -y

sudo apt-get install -y pkg-config

apt install curl -y

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

sudo apt install cargo -y

source $HOME/.cargo/env

rustup update stable

apt install git -y

git clone --branch v0.1.6-alpha https://github.com/eqlabs/pathfinder.git

sudo apt install python3.8-venv

cd pathfinder/py

python3 -m venv .venv

source .venv/bin/activate

PIP_REQUIRE_VIRTUALENV=true pip install --upgrade pip

PIP_REQUIRE_VIRTUALENV=true pip install -r requirements-dev.txt

pytest

 read -p "API KEY: " APIKEY

 cargo build --release --bin pathfinder

sudo tee /etc/systemd/system/starknetd.service > /dev/null <<EOF
[Unit]
Description=StarkNet
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/root/pathfinder/py
ExecStart=/bin/bash -c 'source /root/pathfinder/py/.venv/bin/activate && /root/.cargo/bin/cargo run --release --bin pathfinder -- --ethereum.url https://eth-mainnet.alchemyapi.io/v2/$APIKEY'
Restart=always
RestartSec=10
Environment=RUST_BACKTRACE=1
[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable starknetd
sudo systemctl start starknetd 
journalctl -u starknetd -f -o cat