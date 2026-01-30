// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MiniNFT
 * @dev A simple NFT collection with 1005 unique NFTs that can be minted randomly
 * @notice Mint fee is 0.000001 ETH per NFT
 */
contract MiniNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant MAX_SUPPLY = 1005;
    uint256 public constant MINT_PRICE = 0.000001 ether;

    // State variables
    string public baseTokenURI;
    
    // Efficient randomization tracking
    // map index -> tokenId (0 means value is index + 1)
    mapping(uint256 => uint256) private _tokenMatrix;
    uint256 private _tokensRemaining;

    // Events
    event NFTMinted(address indexed minter, uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        baseTokenURI = _baseTokenURI;
        _tokensRemaining = MAX_SUPPLY;
        // No loop needed! Optimization for low gas deployment
    }

    /**
     * @dev Mint a random NFT from the collection
     * @notice Requires payment of 0.000001 ETH
     */
    function mint() external payable nonReentrant {
        require(_tokensRemaining > 0, "All NFTs have been minted");
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        uint256 tokenId = _mintRandom(msg.sender);

        // Refund excess payment
        if (msg.value > MINT_PRICE) {
            (bool success,) = payable(msg.sender).call{value: msg.value - MINT_PRICE}("");
            require(success, "Refund failed");
        }

        emit NFTMinted(msg.sender, tokenId);
    }

    /**
     * @dev Mint multiple random NFTs at once
     * @param quantity Number of NFTs to mint
     */
    function mintBatch(uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity <= 10, "Max 10 NFTs per batch");
        require(_tokensRemaining >= quantity, "Not enough NFTs available");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");

        uint256 totalPrice = MINT_PRICE * quantity;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _mintRandom(msg.sender);
            emit NFTMinted(msg.sender, tokenId);
        }

        // Refund excess payment
        if (msg.value > totalPrice) {
            (bool success,) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Internal function to handle random minting logic efficiently
     */
    function _mintRandom(address to) private returns (uint256) {
        // Get random index from remaining tokens
        uint256 randIndex = _getRandomIndex();
        
        // Resolve the token ID at that index
        // If matrix[randIndex] is 0, it means it hasn't been swapped yet, so it's randIndex + 1
        uint256 tokenId = _tokenMatrix[randIndex];
        if (tokenId == 0) {
            tokenId = randIndex + 1;
        }

        // Reduce remaining count
        _tokensRemaining--;

        // Swap the last available token into the spot we just used
        // This ensures the used spot effectively "disappears" and is replaced by the last one
        if (_tokensRemaining != randIndex) {
            uint256 lastVal = _tokenMatrix[_tokensRemaining];
            if (lastVal == 0) {
                lastVal = _tokensRemaining + 1;
            }
            _tokenMatrix[randIndex] = lastVal;
        }

        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Generate a pseudo-random index
     */
    function _getRandomIndex() private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _tokensRemaining))
        ) % _tokensRemaining;
    }

    /**
     * @dev Get the number of remaining NFTs available to mint
     */
    function remainingSupply() external view returns (uint256) {
        return _tokensRemaining;
    }

    /**
     * @dev Update the base URI for token metadata
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * @dev Withdraw contract balance to owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner(), balance);
    }

    // Required overrides
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
