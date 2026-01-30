/**
 * MiniNFT Interaction Script
 * Uses generated wallets to interact with the MiniNFT contract on Base Mainnet
 * 
 * Features:
 * - Load wallets from wallets.json
 * - Check wallet balances
 * - Mint NFTs using multiple wallets
 * - Batch operations support
 * - Error handling and logging
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
    // Base Mainnet RPC
    rpcUrl: process.env.BASE_RPC_URL || 'https://mainnet.base.org',

    // Contract details
    contractAddress: '0x80203c0838a1cABe0eAbc0aC9e22f6Abd512cAa9',
    mintPrice: '0.000001', // ETH

    // Network
    chainId: 8453,
    networkName: 'Base Mainnet',

    // Operation settings
    maxConcurrent: 5,  // Max concurrent transactions
    delayBetweenTx: 2000  // Delay between transactions (ms)
};

// Contract ABI (minimal for minting)
const MININFT_ABI = [
    {
        "inputs": [],
        "name": "mint",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [{ "name": "quantity", "type": "uint256" }],
        "name": "mintBatch",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "remainingSupply",
        "outputs": [{ "type": "uint256" }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "totalSupply",
        "outputs": [{ "type": "uint256" }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{ "name": "owner", "type": "address" }],
        "name": "balanceOf",
        "outputs": [{ "type": "uint256" }],
        "stateMutability": "view",
        "type": "function"
    }
];

/**
 * Load wallets from JSON file
 * @returns {Array} Array of wallet objects
 */
function loadWallets() {
    const walletsPath = path.join(__dirname, 'wallets.json');

    if (!fs.existsSync(walletsPath)) {
        console.error('❌ wallets.json not found!');
        console.error('   Run: node generateWallets.js first');
        process.exit(1);
    }

    const data = JSON.parse(fs.readFileSync(walletsPath, 'utf8'));
    console.log(`📂 Loaded ${data.wallets.length} wallets from wallets.json`);
    return data.wallets;
}

/**
 * Create provider and connect to network
 * @returns {ethers.Provider}
 */
function createProvider() {
    const provider = new ethers.JsonRpcProvider(CONFIG.rpcUrl);
    console.log(`🌐 Connected to ${CONFIG.networkName}`);
    return provider;
}

/**
 * Check ETH balance for a wallet
 * @param {ethers.Provider} provider 
 * @param {string} address 
 * @returns {string} Balance in ETH
 */
async function checkBalance(provider, address) {
    const balance = await provider.getBalance(address);
    return ethers.formatEther(balance);
}

/**
 * Check balances for all wallets
 * @param {ethers.Provider} provider 
 * @param {Array} wallets 
 */
async function checkAllBalances(provider, wallets) {
    console.log('');
    console.log('💰 Checking wallet balances...');
    console.log('=====================================');

    let totalBalance = 0n;
    let fundedWallets = 0;

    for (const wallet of wallets) {
        const balance = await provider.getBalance(wallet.address);
        const balanceEth = parseFloat(ethers.formatEther(balance));

        if (balanceEth > 0) {
            fundedWallets++;
            console.log(`   ${wallet.index}. ${wallet.address}: ${balanceEth.toFixed(8)} ETH`);
        }

        totalBalance += balance;
    }

    console.log('');
    console.log(`📊 Summary:`);
    console.log(`   - Total wallets: ${wallets.length}`);
    console.log(`   - Funded wallets: ${fundedWallets}`);
    console.log(`   - Total balance: ${ethers.formatEther(totalBalance)} ETH`);
}

/**
 * Get contract information
 * @param {ethers.Provider} provider 
 */
async function getContractInfo(provider) {
    const contract = new ethers.Contract(CONFIG.contractAddress, MININFT_ABI, provider);

    console.log('');
    console.log('📜 Contract Information');
    console.log('=====================================');
    console.log(`   Address: ${CONFIG.contractAddress}`);

    try {
        const totalSupply = await contract.totalSupply();
        const remaining = await contract.remainingSupply();

        console.log(`   Total Minted: ${totalSupply.toString()}`);
        console.log(`   Remaining: ${remaining.toString()}`);
        console.log(`   Mint Price: ${CONFIG.mintPrice} ETH`);
    } catch (error) {
        console.log(`   ⚠️  Could not fetch contract state: ${error.message}`);
    }
}

/**
 * Mint NFT using a specific wallet
 * @param {ethers.Provider} provider 
 * @param {Object} wallet 
 * @param {number} quantity 
 */
async function mintNFT(provider, wallet, quantity = 1) {
    const signer = new ethers.Wallet(wallet.privateKey, provider);
    const contract = new ethers.Contract(CONFIG.contractAddress, MININFT_ABI, signer);

    const value = ethers.parseEther(CONFIG.mintPrice) * BigInt(quantity);

    console.log(`🎨 Minting ${quantity} NFT(s) from wallet ${wallet.index} (${wallet.address.slice(0, 10)}...)`);

    try {
        let tx;
        if (quantity === 1) {
            tx = await contract.mint({ value });
        } else {
            tx = await contract.mintBatch(quantity, { value });
        }

        console.log(`   📤 Transaction sent: ${tx.hash}`);

        const receipt = await tx.wait();
        console.log(`   ✅ Confirmed in block ${receipt.blockNumber}`);

        return { success: true, hash: tx.hash, wallet: wallet.address };
    } catch (error) {
        console.log(`   ❌ Failed: ${error.message}`);
        return { success: false, error: error.message, wallet: wallet.address };
    }
}

/**
 * Batch mint using multiple wallets
 * @param {ethers.Provider} provider 
 * @param {Array} wallets 
 * @param {number} nftsPerWallet 
 */
async function batchMint(provider, wallets, nftsPerWallet = 1) {
    console.log('');
    console.log('🚀 Starting batch mint operation');
    console.log('=====================================');
    console.log(`   Wallets: ${wallets.length}`);
    console.log(`   NFTs per wallet: ${nftsPerWallet}`);
    console.log(`   Total NFTs: ${wallets.length * nftsPerWallet}`);
    console.log('');

    const results = {
        successful: [],
        failed: []
    };

    for (let i = 0; i < wallets.length; i += CONFIG.maxConcurrent) {
        const batch = wallets.slice(i, i + CONFIG.maxConcurrent);

        const promises = batch.map(wallet => mintNFT(provider, wallet, nftsPerWallet));
        const batchResults = await Promise.all(promises);

        batchResults.forEach(result => {
            if (result.success) {
                results.successful.push(result);
            } else {
                results.failed.push(result);
            }
        });

        // Delay between batches
        if (i + CONFIG.maxConcurrent < wallets.length) {
            console.log(`   ⏳ Waiting ${CONFIG.delayBetweenTx}ms before next batch...`);
            await new Promise(resolve => setTimeout(resolve, CONFIG.delayBetweenTx));
        }
    }

    console.log('');
    console.log('📊 Batch Mint Results');
    console.log('=====================================');
    console.log(`   ✅ Successful: ${results.successful.length}`);
    console.log(`   ❌ Failed: ${results.failed.length}`);

    return results;
}

/**
 * Sleep helper
 * @param {number} ms 
 */
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Display help
 */
function showHelp() {
    console.log('');
    console.log('🪵 MiniNFT Interaction Script');
    console.log('=====================================');
    console.log('');
    console.log('Usage: node interactionScript.js [command]');
    console.log('');
    console.log('Commands:');
    console.log('   info      - Show contract information');
    console.log('   balances  - Check balances of all wallets');
    console.log('   mint      - Mint 1 NFT using first funded wallet');
    console.log('   batch     - Batch mint using all funded wallets');
    console.log('   help      - Show this help message');
    console.log('');
    console.log('Environment Variables:');
    console.log('   BASE_RPC_URL - Custom RPC URL for Base network');
    console.log('');
    console.log('Example:');
    console.log('   node interactionScript.js info');
    console.log('   node interactionScript.js balances');
    console.log('');
}

/**
 * Main execution
 */
async function main() {
    const args = process.argv.slice(2);
    const command = args[0] || 'help';

    console.log('');
    console.log('🪵 MiniNFT Interaction Script');
    console.log('=====================================');

    const provider = createProvider();
    const wallets = loadWallets();

    switch (command.toLowerCase()) {
        case 'info':
            await getContractInfo(provider);
            break;

        case 'balances':
            await checkAllBalances(provider, wallets);
            break;

        case 'mint':
            // Find first funded wallet
            for (const wallet of wallets) {
                const balance = await provider.getBalance(wallet.address);
                if (balance > ethers.parseEther(CONFIG.mintPrice)) {
                    await mintNFT(provider, wallet, 1);
                    break;
                }
            }
            console.log('⚠️  No funded wallets found!');
            break;

        case 'batch':
            // Find all funded wallets
            const fundedWallets = [];
            for (const wallet of wallets) {
                const balance = await provider.getBalance(wallet.address);
                if (balance > ethers.parseEther(CONFIG.mintPrice)) {
                    fundedWallets.push(wallet);
                }
            }

            if (fundedWallets.length === 0) {
                console.log('⚠️  No funded wallets found!');
                break;
            }

            await batchMint(provider, fundedWallets, 1);
            break;

        case 'help':
        default:
            showHelp();
    }

    console.log('');
}

// Run main
main().catch(console.error);
