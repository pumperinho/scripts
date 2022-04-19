#!/bin/bash
cd $HOME
wget https://raw.githubusercontent.com/pumperinho/scripts/main/logo.sh
chmod +x logo.sh
./logo.sh

sudo apt update && sudo apt upgrade -y
sudo apt install pkg-config cargo libssl-dev clang jq -y

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

rustup default nightly

git clone https://github.com/penumbra-zone/penumbra
cd penumbra
git checkout 007-herse
cargo update

cargo build --release --bin pcli

cargo run --quiet --release --bin pcli wallet generate | tee penumbra.txt

export RUST_LOG=info

cargo run --quiet --release --bin pcli sync

rm -rf logo.sh