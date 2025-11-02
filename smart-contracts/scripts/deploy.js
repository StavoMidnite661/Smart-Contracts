const hre = require("hardhat");

async function main() {
  const network = hre.network.name;
  console.log(`Deploying VirtualCardBridge contract to ${network}...`);

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");

  // Get SOVR token address from environment or use placeholder
  const sovTokenAddress = process.env.SOVR_TOKEN_ADDRESS || "0x1234567890123456789012345678901234567890";
  console.log("Using SOVR token address:", sovTokenAddress);
  
  const VirtualCardBridge = await hre.ethers.getContractFactory("VirtualCardBridge");
  const bridge = await VirtualCardBridge.deploy(sovTokenAddress);

  await bridge.waitForDeployment();
  const address = await bridge.getAddress();

  console.log("VirtualCardBridge deployed to:", address);
  console.log("\nContract ABI saved for frontend integration");
  console.log("Verify on Etherscan:");
  console.log(`npx hardhat verify --network ${network} ${address}`);
  
  // Save deployment info
  const fs = require("fs");
  const deploymentInfo = {
    network: network,
    contractAddress: address,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    chainId: hre.network.config.chainId
  };
  
  fs.writeFileSync(
    "../deployment-info.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("\nDeployment info saved to deployment-info.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
