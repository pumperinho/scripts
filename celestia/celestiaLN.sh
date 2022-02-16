#!/bin/bash
# check variables
echo -e "$FULL_NODE_IP\n$TRUSTED_HASH"

# output example
# /ip4/194.163.191.41/tcp/2121/p2p/12D3KooWFWvUJDTx9pKAch4TW5if8YZwEKWQ8SFYVH2fRbN7vp4P
# 4632277C441CA6155C4374AC56048CF4CFE3CBB2476E07A548644435980D5E17

# IF OUTPUT OK! - DO NEXT ->

# init 
rm -rf $HOME/.celestia-light
celestia light init --headers.trusted-peer $FULL_NODE_IP --headers.trusted-hash $TRUSTED_HASH

# change port of light client
port=2122
sed -i.bak -e "s|ListenAddresses *=.*|ListenAddresses = \[\"/ip4/0.0.0.0/tcp/$port\", \"/ip6/::/tcp/$port\"\]|" $HOME/.celestia-light/config.toml
sed -i.bak -e "s|NoAnnounceAddresses *=.*|NoAnnounceAddresses = \[\"/ip4/0.0.0.0/tcp/$port\", \"/ip4/127.0.0.1/tcp/$port\", \"/ip6/::/tcp/$port\"\]|" $HOME/.celestia-light/config.toml

sudo tee /etc/systemd/system/celestia-light.service > /dev/null <<EOF
[Unit]
  Description=celestia-light
  After=network-online.target
[Service]
  User=$USER
  ExecStart=$(which celestia) light start
  Restart=on-failure
  RestartSec=10
  LimitNOFILE=4096
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl enable celestia-light
sudo systemctl daemon-reload
sudo systemctl restart celestia-light && journalctl -u celestia-light -f -o cat 