# Smart Contract Deployment Instructions

This guide provides the steps to deploy the `VirtualCardBridge` smart contract to the Base mainnet.

**SECURITY WARNING:** It is critical that you use a **new, secure wallet** for this deployment. The previous wallet was compromised. Do not reuse the old private key or wallet address.

## Prerequisites

1.  **Node.js and npm:** Ensure you have Node.js (v18 or later) and npm installed on your machine.
2.  **A New Secure Wallet:** Create a new Ethereum wallet. Make sure to back up your seed phrase securely offline.
3.  **ETH on Base Mainnet:** Fund your new wallet with enough ETH on the Base mainnet to cover the gas fees for deployment.
4.  **Basescan API Key:** Create an account on [Basescan](https://basescan.org/) and generate a new API key for contract verification.
5.  **SOVR Token Address:** You will need the address of the SOVR token on the Base mainnet. The address you provided previously was `0xeadec4b261da230822ddb184ad7a74024384f1e6`.

## Deployment Steps

### Step 1: Set Up Environment Variables

1.  Navigate to the `smart-contracts` directory.
2.  Create a new file named `.env`.
3.  Add the following content to the `.env` file, replacing the placeholder values with your own secure information:

    ```
    # Your secure Base mainnet RPC URL (e.g., from Alchemy or Infura)
    BASE_RPC_URL=https://mainnet.base.org

    # The private key from your NEW, SECURE wallet
    DEPLOYER_PRIVATE_KEY=your_new_private_key_here

    # Your Basescan API key
    BASESCAN_API_KEY=your_basescan_api_key_here

    # The SOVR token address on Base mainnet
    SOVR_TOKEN_ADDRESS=0xeadec4b261da230822ddb184ad7a74024384f1e6
    ```

    **IMPORTANT:** Double-check that you are using the private key from your **new wallet**.

### Step 2: Install Dependencies

Open your terminal, navigate to the `smart-contracts` directory, and run the following command to install the necessary packages:

```bash
npm install
```

### Step 3: Compile the Contract

Compile the smart contract to ensure everything is set up correctly:

```bash
npx hardhat compile
```

You should see a message like `Compiled 12 Solidity files successfully`.

### Step 4: Deploy the Contract

Run the deployment script to deploy the contract to the Base mainnet:

```bash
npx hardhat run scripts/deploy.js --network base
```

The script will output the address of the deployed contract. Save this address.

### Step 5: Verify the Contract on Basescan

After the deployment is complete, the script will print a command to verify the contract on Basescan. It will look like this:

```
npx hardhat verify --network base DEPLOYED_CONTRACT_ADDRESS
```

Replace `DEPLOYED_CONTRACT_ADDRESS` with the actual address of your deployed contract and run the command. This will make your contract's source code visible and verifiable on Basescan.

You have now successfully deployed and verified your smart contract.
