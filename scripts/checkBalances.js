/**
 * MiniNFT Balance Checker
 * Quick utility to check the balance status of all generated wallets
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

const RPC_URL = process.env.BASE_RPC_URL || 'https://mainnet.base.org';
const MINT_PRICE = ethers.parseEther('0.000001');

async function main() {
    console.log('🪵 MiniNFT Balance Checker');
    console.log('==========================\n');

    // Load wallets
    const walletsPath = path.join(__dirname, 'wallets.json');
    if (!fs.existsSync(walletsPath)) {
        console.log('❌ wallets.json not found! Run generateWallets.js first.');
        return;
    }

    const { wallets } = JSON.parse(fs.readFileSync(walletsPath, 'utf8'));
    const provider = new ethers.JsonRpcProvider(RPC_URL);

    console.log(`📊 Checking ${wallets.length} wallets...\n`);

    let funded = 0;
    let canMint = 0;
    let totalBalance = 0n;

    for (const wallet of wallets) {
        const balance = await provider.getBalance(wallet.address);
        totalBalance += balance;

        if (balance > 0n) {
            funded++;
            if (balance >= MINT_PRICE) {
                canMint++;
            }
        }
    }

    console.log('📈 Results:');
    console.log(`   Total wallets: ${wallets.length}`);
    console.log(`   Funded wallets: ${funded}`);
    console.log(`   Can mint (≥${ethers.formatEther(MINT_PRICE)} ETH): ${canMint}`);
    console.log(`   Total balance: ${ethers.formatEther(totalBalance)} ETH`);
    console.log('');
}

main().catch(console.error);
