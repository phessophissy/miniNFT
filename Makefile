.PHONY: help install build test deploy clean format lint frontend-dev frontend-build

help:
@echo "Available commands:"
@echo "  install        - Install all dependencies"
@echo "  build          - Build smart contracts"
@echo "  test           - Run all tests"
@echo "  deploy         - Deploy to Base mainnet"
@echo "  clean          - Clean build artifacts"
@echo "  format         - Format Solidity code"
@echo "  lint           - Lint Solidity code"
@echo "  frontend-dev   - Start frontend development server"
@echo "  frontend-build - Build frontend for production"

install:
forge install
cd frontend && npm install

build:
forge build --sizes

test:
forge test -vvv

deploy:
source .env && forge script script/DeployMiniNFT.s.sol --rpc-url $$BASE_RPC_URL --broadcast --verify

clean:
forge clean
rm -rf frontend/dist

format:
forge fmt

lint:
forge fmt --check

frontend-dev:
cd frontend && npm run dev

frontend-build:
cd frontend && npm run build
