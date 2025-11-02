#!/usr/bin/env python3
"""
Emergency Contract Deployment Script
Deploys VirtualCardBridge to Sepolia using Web3.py
"""

import json
import os
from web3 import Web3
from pathlib import Path

# Load environment variables
PRIVATE_KEY = "949043acc88f50cc159e8b07e07fd57eda53d49ec0a5b9555791cef1db7a366f"
SOVR_TOKEN = "0xeadec4b261da230822ddb184ad7a74024384f1e6"
RPC_URL = "https://rpc.sepolia.org"

def main():
    print("🚀 Deploying VirtualCardBridge to Sepolia...")
    
    # Connect to Sepolia
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    
    if not w3.is_connected():
        print("❌ Failed to connect to Sepolia RPC")
        return
    
    print(f"✅ Connected to Sepolia (Chain ID: {w3.eth.chain_id})")
    
    # Setup account
    account = w3.eth.account.from_key(PRIVATE_KEY)
    print(f"📍 Deployer: {account.address}")
    
    # Check balance
    balance = w3.eth.get_balance(account.address)
    balance_eth = w3.from_wei(balance, 'ether')
    print(f"💰 Balance: {balance_eth} ETH")
    
    if balance == 0:
        print("\n❌ NO ETH BALANCE!")
        print("Get Sepolia testnet ETH from:")
        print("  • https://sepoliafaucet.com")
        print("  • https://www.alchemy.com/faucets/ethereum-sepolia")
        return
    
    print("\n⚠️  Contract compilation required.")
    print("Please use Remix IDE for deployment:")
    print(f"  1. Go to https://remix.ethereum.org")
    print(f"  2. Deploy with SOVR address: {SOVR_TOKEN}")
    print(f"  3. Deploy from wallet: {account.address}")

if __name__ == "__main__":
    main()
