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

# Start Solidity Contract
rm src/Counter.sol

cat <<'EOF' > src/Contract.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract SimpleStorage {

    uint256 public storedData; //Do not set 0 manually it wastes gas!

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

# Hỏi số lượng contract cần deploy
read -p "How many contracts do you want to deploy? " COUNT

echo "" > contract-address.txt

for ((i=1; i<=COUNT; i++)); do
  echo "🚀 Deploying contract #$i..."
  ADDRESS=$(forge create src/Contract.sol:SimpleStorage \
    --private-key "$PRIVATE_KEY" \
    --rpc-url https://rpc.dev.gblend.xyz/ \
    --broadcast \
    --json | jq -r '.deployedTo')

  echo "$ADDRESS" >> contract-address.txt
  echo "✅ Contract #$i deployed at: $ADDRESS"

  echo "⏳ Waiting for contract to appear on chain..."
  while true; do
    CODE=$(cast code "$ADDRESS" --rpc-url https://rpc.dev.gblend.xyz/)
    if [ "$CODE" != "0x" ]; then
      echo "✅ Contract is now available on chain!"
      RANDOM_WAIT=$((RANDOM % 6 + 5))
      echo "⏳ Waiting $RANDOM_WAIT seconds to allow Blockscout to index..."
      sleep $RANDOM_WAIT
      break
    fi
    sleep 3
  done

  echo "🔍 Verifying contract #$i..."
  forge verify-contract \
    --rpc-url https://rpc.dev.gblend.xyz/ \
    "$ADDRESS" \
    src/Contract.sol:SimpleStorage \
    --verifier blockscout \
    --verifier-url https://blockscout.dev.gblend.xyz/api/

  echo "🔗 View: https://blockscout.dev.gblend.xyz/address/$ADDRESS"
  echo ""
done
