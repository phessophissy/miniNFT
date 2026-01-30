/**
 * MiniNFT Contract Status Checker
 * Quick utility to check current contract state
 */

const { ethers } = require('ethers');

const RPC_URL = process.env.BASE_RPC_URL || 'https://mainnet.base.org';
const CONTRACT_ADDRESS = '0x80203c0838a1cABe0eAbc0aC9e22f6Abd512cAa9';

const ABI = [
    "function totalSupply() view returns (uint256)",
    "function remainingSupply() view returns (uint256)",
    "function MAX_SUPPLY() view returns (uint256)",
    "function MINT_PRICE() view returns (uint256)",
    "function owner() view returns (address)"
];

async function main() {
    console.log('🪵 MiniNFT Contract Status');
    console.log('===========================\n');

    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

    try {
        const [totalSupply, remaining, maxSupply, mintPrice, owner] = await Promise.all([
            contract.totalSupply(),
            contract.remainingSupply(),
            contract.MAX_SUPPLY(),
            contract.MINT_PRICE(),
            contract.owner()
        ]);

        const progress = (Number(totalSupply) / Number(maxSupply) * 100).toFixed(2);

        console.log('📜 Contract Information:');
        console.log(`   Address: ${CONTRACT_ADDRESS}`);
        console.log(`   Owner: ${owner}`);
        console.log('');
        console.log('📊 Minting Status:');
        console.log(`   Total Supply: ${totalSupply.toString()}`);
        console.log(`   Remaining: ${remaining.toString()}`);
        console.log(`   Max Supply: ${maxSupply.toString()}`);
        console.log(`   Progress: ${progress}%`);
        console.log(`   Mint Price: ${ethers.formatEther(mintPrice)} ETH`);
        console.log('');

    } catch (error) {
        console.log(`❌ Error: ${error.message}`);
    }
}

main().catch(console.error);
