/**
 * Verification Script
 * Checks if the environment is correctly set up for MiniNFT development
 */

const fs = require('fs');
const path = require('path');

const REQUIRED_FILES = [
    'generateWallets.js',
    'interactionScript.js',
    'checkBalances.js',
    'contractStatus.js',
    'package.json',
    'README.md'
];

function verify() {
    console.log('🔍 Verifying MiniNFT Scripts Environment...');
    console.log('==========================================\n');

    let missing = 0;

    REQUIRED_FILES.forEach(file => {
        const filePath = path.join(__dirname, file);
        if (fs.existsSync(filePath)) {
            console.log(`✅ Found: ${file}`);
        } else {
            console.log(`❌ Missing: ${file}`);
            missing++;
        }
    });

    console.log('\n==========================================');
    if (missing === 0) {
        console.log('🎉 Environment verification successful!');
    } else {
        console.log(`⚠️  Found ${missing} missing files.`);
    }
}

verify();
