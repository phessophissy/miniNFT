FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash \
    && . ~/.bashrc \
    && foundryup

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./
COPY frontend/package*.json ./frontend/

# Install Node.js dependencies
RUN npm install
RUN cd frontend && npm install

# Copy the rest of the project
COPY . .

# Install Foundry dependencies
RUN forge install

# Default command
CMD ["make", "help"]
