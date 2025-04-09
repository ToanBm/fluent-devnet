#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)
# Logo

echo     "*********************************************"
echo     "Githuh: https://github.com/ToanBm"
echo     "X: https://x.com/buiminhtoan1985"
echo -e "\e[0m"

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

# Install Foundry:
curl -L https://foundry.paradigm.xyz | bash
source /home/codespace/.bashrc
foundryup

# Start Foundry Project
forge init --force

# Set contract:
# Random symbol
TOKEN_SYMBOL=$(tr -dc A-Z </dev/urandom | head -c 3)

# Random total supply (1_000_000 → 9_000_000)
TOTAL_SUPPLY=$(( (RANDOM % 9 + 1) * 1000000 ))

echo "🪙 Symbol: $TOKEN_SYMBOL"
echo "💰 Total Supply: $TOTAL_SUPPLY"

# Start Solidity Contract
rm src/Counter.sol

cat <<EOF > src/Contract.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract SimpleStorage {

    uint256 public storedData; // Do not set 0 manually it wastes gas!

    string public symbol = "$TOKEN_SYMBOL";
    uint256 public totalSupply = $TOTAL_SUPPLY;

    event setEvent();

    function set(uint256 x) public {
        storedData = x;
        emit setEvent();
    }
}
EOF

## Crear .env file
read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY

print_command "Generating .env file..."
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Deploy contract
export $(grep -v '^#' .env | xargs)

ADDRESS=$(forge create src/Contract.sol:SimpleStorage \
  --private-key "$PRIVATE_KEY" \
  --rpc-url https://rpc.dev.gblend.xyz/ \
  --broadcast \
  --json | jq -r '.deployedTo')

echo "$ADDRESS" > contract-address.txt
echo "✅ Deployed to: $ADDRESS"

sleep 3

# Verify contract
export $(grep -v '^#' .env | xargs)

ADDRESS=$(cat contract-address.txt)

forge verify-contract \
  --rpc-url https://rpc.dev.gblend.xyz/ \
  "$ADDRESS" \
  src/Contract.sol:SimpleStorage \
  --verifier blockscout \
  --verifier-url https://blockscout.dev.gblend.xyz/api/

echo "✅ Done!"
echo "🔗 Check your contract:"
echo "https://blockscout.dev.gblend.xyz/address/$ADDRESS"

  














