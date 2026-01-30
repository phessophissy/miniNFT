# MiniNFT Scripts

Scripts for wallet generation and contract interaction on Base Mainnet.

## Setup

```bash
cd scripts
npm install
```

## Generate Wallets

Generate 250 EVM wallets for testing:

```bash
npm run generate
# or
node generateWallets.js
```

This creates `wallets.json` containing 250 wallet addresses and private keys.

> ⚠️ **WARNING**: These wallets are for TESTING ONLY. Never fund them with real assets without proper security measures.

## Interaction Script

Interact with the MiniNFT contract using generated wallets:

```bash
# Show contract info
node interactionScript.js info

# Check wallet balances
node interactionScript.js balances

# Mint using first funded wallet
node interactionScript.js mint

# Batch mint with all funded wallets
node interactionScript.js batch
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BASE_RPC_URL` | Base network RPC URL | `https://mainnet.base.org` |

## Contract Details

- **Network**: Base Mainnet (Chain ID: 8453)
- **Contract**: `0x80203c0838a1cABe0eAbc0aC9e22f6Abd512cAa9`
- **Mint Price**: 0.000001 ETH
- **Max Supply**: 1005

## Files

| File | Description |
|------|-------------|
| `generateWallets.js` | Generates 250 EVM wallets |
| `interactionScript.js` | Contract interaction utilities |
| `wallets.json` | Generated wallets (gitignored) |
| `package.json` | Dependencies and scripts |
