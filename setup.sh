#!/bin/bash

# MiniNFT Development Setup Script
echo "🚀 Setting up MiniNFT development environment..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry is not installed. Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup
fi

# Install dependencies
echo "📦 Installing dependencies..."
forge install
cd frontend && npm install
cd ..

# Copy environment template
if [ ! -f .env ]; then
    echo "📋 Setting up environment file..."
    cp .env.example .env
    echo "✅ Created .env file from template. Please fill in your values."
fi

echo "🎉 Setup complete!"
echo ""
echo "Available commands:"
echo "  make help          - Show all available commands"
echo "  make install       - Install all dependencies"#!/bin/bash

# MiniNFT Development Semart co
# MiniNFTchoecho "🚀 Setting up MiniNFT devs"
# Check if Node.js is installed
if ! command -v node &> seif ! command -vcho "Next steps:"    echo "❌ Node.js is not installedyo    exit 1
fi

# Check if Foundry is installed
if ! command -v fobuild the fi

# Che"

choif . Run 'make frontend-dev' to start the development server"
