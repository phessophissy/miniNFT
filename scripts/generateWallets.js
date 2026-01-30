/**
 * MiniNFT Wallet Generator
 * Generates 250 EVM wallets for testing purposes
 * 
 * IMPORTANT: These wallets are for TESTING ONLY
 * Never fund these wallets with real assets without proper security measures
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

// Number of wallets to generate
const WALLET_COUNT = 250;

/**
 * Generate a single EVM wallet
 * @returns {Object} Wallet object with address and privateKey
 */
function generateWallet() {
    const wallet = ethers.Wallet.createRandom();
    return {
        address: wallet.address,
        privateKey: wallet.privateKey,
        mnemonic: wallet.mnemonic?.phrase || null
    };
}

/**
 * Generate multiple wallets
 * @param {number} count - Number of wallets to generate
 * @returns {Array} Array of wallet objects
 */
function generateWallets(count) {
    console.log(`🔐 Generating ${count} EVM wallets...`);
    const wallets = [];

    for (let i = 0; i < count; i++) {
        const wallet = generateWallet();
        wallets.push({
            index: i + 1,
            address: wallet.address,
            privateKey: wallet.privateKey
        });

        if ((i + 1) % 50 === 0) {
            console.log(`   Generated ${i + 1}/${count} wallets...`);
        }
    }

    console.log(`✅ Successfully generated ${count} wallets!`);
    return wallets;
}

/**
 * Save wallets to JSON file
 * @param {Array} wallets - Array of wallet objects
 * @param {string} filename - Output filename
 */
function saveWallets(wallets, filename) {
    const outputPath = path.join(__dirname, filename);

    const output = {
        generated: new Date().toISOString(),
        network: 'Base Mainnet',
        chainId: 8453,
        warning: 'FOR TESTING PURPOSES ONLY - DO NOT FUND WITH REAL ASSETS',
        totalWallets: wallets.length,
        wallets: wallets
    };

    fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));
    console.log(`💾 Wallets saved to: ${outputPath}`);
}

/**
 * Main execution
 */
function main() {
    console.log('');
    console.log('🪵 MiniNFT Wallet Generator');
    console.log('=====================================');
    console.log('');

    // Generate wallets
    const wallets = generateWallets(WALLET_COUNT);

    // Save to file
    saveWallets(wallets, 'wallets.json');

    console.log('');
    console.log('📊 Summary:');
    console.log(`   - Total wallets: ${wallets.length}`);
    console.log(`   - First address: ${wallets[0].address}`);
    console.log(`   - Last address: ${wallets[wallets.length - 1].address}`);
    console.log('');
    console.log('⚠️  WARNING: These wallets are for TESTING ONLY!');
    console.log('   Never fund with real assets without proper security.');
    console.log('');
}

// Run the script
main();
