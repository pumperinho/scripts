#!/bin/bash
echo "IP = "$(wget -qO- eth0.me)
echo "COHO_NODENAME = "${COHO_NODENAME}
echo "COHO_WALLET = "${COHO_WALLET}
echo "COHO_ADDR = "${COHO_ADDR}
echo "COHO_VALOPER = "${COHO_VALOPER}
rm info.sh
