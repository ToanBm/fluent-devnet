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

sleep 5

foundryup

# Start Foundry Project
forge init --force

# Set contract:
read -p "Enter token name: " TOKEN_NAME
read -p "Enter token symbol (e.g. ABC): " TOKEN_SYMBOL
read -p "Enter total supply (e.g. 1000000): " TOTAL_SUPPLY

# Creat contract
rm src/Counter.sol

cat <<EOF > src/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MyToken {
    string public name = "$TOKEN_NAME";
    string public symbol = "$TOKEN_SYMBOL";
    uint8 public decimals = 18;
    uint256 public totalSupply = $TOTAL_SUPPLY * (10 ** uint256(decimals));

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function mint(uint256 amount) public {
        uint256 mintAmount = amount * (10 ** uint256(decimals));
        totalSupply += mintAmount;
        balanceOf[msg.sender] += mintAmount;
        emit Transfer(address(0), msg.sender, mintAmount);
    }
}
EOF

## Crear .env file
read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY

print_command "Generating .env file..."
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# 1. Deploy contract
export $(grep -v '^#' .env | xargs)

ADDRESS=$(forge create src/MyToken.sol:MyToken \
  --private-key "$PRIVATE_KEY" \
  --rpc-url https://rpc.dev.gblend.xyz/ \
  --broadcast \
  --json | jq -r '.deployedTo')

echo "$ADDRESS" > contract-address.txt
echo "✅ Deployed to: $ADDRESS"

sleep 3

# 2. Verify contract
export $(grep -v '^#' .env | xargs)

ADDRESS=$(cat contract-address.txt)

forge verify-contract \
  --rpc-url https://rpc.dev.gblend.xyz/ \
  "$ADDRESS" \
  src/MyToken.sol:MyToken \
  --verifier blockscout \
  --verifier-url https://blockscout.dev.gblend.xyz/api/

echo "✅ Done!"
echo "🔗 Check your contract:"
echo "https://blockscout.dev.gblend.xyz/address/$ADDRESS"

# 3. Transfer token
# Random wallet
TO_ADDRESS="0x$(tr -dc 'a-f0-9' < /dev/urandom | head -c 40)"

# Random amount from 1000 to 100000
AMOUNT=$(( (RANDOM % 99001) + 1000 ))
echo "🔢 Amount of tokens to send: $AMOUNT"

# Load environment variables and contract address
export $(grep -v '^#' .env | xargs)
export CONTRACT_ADDRESS=$(cat contract-address.txt)

# Send tokens using Foundry's cast
cast send $CONTRACT_ADDRESS \
  "transfer(address,uint256)" $TO_ADDRESS $AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url https://rpc.dev.gblend.xyz/





  














