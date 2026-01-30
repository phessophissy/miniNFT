# Contributing to MiniNFT

We welcome contributions to the MiniNFT project!

## Development Guidelines

1. **Theme adherence**: All UI changes must adhere to the "Wooden" design system.
   - Use `var(--wood-grain)`, `var(--wood-dark)`, and `var(--primary)` variables.
   - Animations should be organic (sway, float, glow).
   - Emojis should be nature/wood related where possible (🪵, 🌳, 🌲).

2. **Commit Messages**: Follow Conventional Commits format.
   - `feat(scope): message`
   - `fix(scope): message`
   - `style(scope): message`
   - `docs(scope): message`

3. **Smart Contracts**:
   - Run tests before submitting changes: `forge test`
   - Ensure gas optimization where possible.

## Setup

```bash
git clone https://github.com/phessophissy/miniNFT.git
cd miniNFT
npm install
cd frontend && npm install
```

## Running Scripts

See `scripts/README.md` for details on generating wallets and interacting with the contract.
