const { ethers } = require('ethers');
const fs = require('fs');
require('dotenv').config();

async function main() {
  console.log("🚀 Deploying VirtualCardBridge to Sepolia...");
  
  // Setup provider and wallet
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL || 'https://rpc.sepolia.org');
  const wallet = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY, provider);
  
  console.log("📍 Deployer address:", wallet.address);
  
  const balance = await provider.getBalance(wallet.address);
  console.log("💰 Balance:", ethers.formatEther(balance), "ETH");
  
  if (balance === 0n) {
    console.error("❌ ERROR: No ETH balance. Get Sepolia testnet ETH from https://sepoliafaucet.com");
    process.exit(1);
  }
  
  // Read the compiled contract
  const contractSource = fs.readFileSync('./VirtualCardBridge.sol', 'utf8');
  
  // For quick deployment, we'll use the contract bytecode directly
  // This is a simplified version - in production you'd compile with solc
  console.log("⚠️  Manual deployment required:");
  console.log("\n📋 DEPLOYMENT INSTRUCTIONS:");
  console.log("1. Go to https://remix.ethereum.org");
  console.log("2. Create new file 'VirtualCardBridge.sol' and paste contract code");
  console.log("3. Install dependencies: @openzeppelin/contracts");
  console.log("4. Compile with Solidity 0.8.20");
  console.log("5. Deploy to Sepolia with constructor parameter:");
  console.log("   SOVR_TOKEN_ADDRESS:", process.env.SOVR_TOKEN_ADDRESS);
  console.log("6. Copy deployed contract address and update frontend");
  console.log("\n💡 Alternative: Get Sepolia ETH and I'll help deploy automatically");
}

main().catch(console.error);
