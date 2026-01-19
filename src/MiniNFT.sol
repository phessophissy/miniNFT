// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MiniNFT
 * @dev A simple NFT collection with 505 unique NFTs that can be minted randomly
 * @notice Mint fee is 0.00001 ETH per NFT
 */
contract MiniNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant MAX_SUPPLY = 505;
    uint256 public constant MINT_PRICE = 0.00001 ether;

    // State variables
    string public baseTokenURI;
    uint256 private _nextTokenId;

    // Array to track available token IDs for random minting
    uint256[] private _availableTokenIds;

    // Events
    event NFTMinted(address indexed minter, uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event BulkMintExecuted(address indexed minter, uint256 quantity, uint256 totalCost);
    event BulkTransferExecuted(address indexed from, address indexed to, uint256[] tokenIds);
    event BulkMetadataUpdated(uint256[] tokenIds, string[] newURIs);

    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        baseTokenURI = _baseTokenURI;

        // Initialize available token IDs (1 to 505)
        for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
            _availableTokenIds.push(i);
        }
    }

    /**
     * @dev Mint a random NFT from the collection
     * @notice Requires payment of 0.00001 ETH
     */
    function mint() external payable nonReentrant {
        require(_availableTokenIds.length > 0, "All NFTs have been minted");
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        // Get a random token ID from available tokens
        uint256 randomIndex = _getRandomIndex();
        uint256 tokenId = _availableTokenIds[randomIndex];

        // Remove the token ID from available tokens
        _removeTokenIdAtIndex(randomIndex);

        // Mint the NFT
        _safeMint(msg.sender, tokenId);

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
        require(_availableTokenIds.length >= quantity, "Not enough NFTs available");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 randomIndex = _getRandomIndex();
            uint256 tokenId = _availableTokenIds[randomIndex];
            _removeTokenIdAtIndex(randomIndex);
            _safeMint(msg.sender, tokenId);
            emit NFTMinted(msg.sender, tokenId);
        }

        // Refund excess payment
        uint256 totalPrice = MINT_PRICE * quantity;
        if (msg.value > totalPrice) {
            (bool success,) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Generate a pseudo-random index
     */
    function _getRandomIndex() private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _availableTokenIds.length))
        ) % _availableTokenIds.length;
    }

    /**
     * @dev Remove a token ID from the available array by swapping with last element
     */
    function _removeTokenIdAtIndex(uint256 index) private {
        uint256 lastIndex = _availableTokenIds.length - 1;
        if (index != lastIndex) {
            _availableTokenIds[index] = _availableTokenIds[lastIndex];
        }
        _availableTokenIds.pop();
    }

    /**
     * @dev Get the number of remaining NFTs available to mint
     */
    function remainingSupply() external view returns (uint256) {
        return _availableTokenIds.length;
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

    /**
     * @dev Get all available token IDs
     */
    function getAvailableTokenIds() external view returns (uint256[] memory) {
        return _availableTokenIds;
    }

    /*//////////////////////////////////////////////////////////////
                           BULK OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct for bulk transfer parameters
    struct BulkTransfer {
        uint256 tokenId;
        address to;
    }

    /// @notice Struct for bulk metadata update parameters
    struct BulkMetadataUpdate {
        uint256 tokenId;
        string newURI;
    }

    /// @notice Transfer multiple NFTs to different recipients in one transaction
    /// @param transfers Array of transfer parameters (up to 20 transfers per transaction)
    function bulkTransfer(BulkTransfer[] calldata transfers) external nonReentrant {
        uint256 totalTransfers = transfers.length;
        require(totalTransfers > 0 && totalTransfers <= 20, "Invalid transfer count");

        for (uint256 i = 0; i < totalTransfers; i++) {
            BulkTransfer calldata transferData = transfers[i];
            require(ownerOf(transferData.tokenId) == msg.sender, "Not token owner");
            require(transferData.to != address(0), "Invalid recipient");

            _transfer(msg.sender, transferData.to, transferData.tokenId);
        }

        emit BulkTransferExecuted(msg.sender, address(0), _extractTokenIds(transfers));
    }

    /// @notice Transfer multiple NFTs to the same recipient in one transaction
    /// @param tokenIds Array of token IDs to transfer
    /// @param to Recipient address
    function bulkTransferToRecipient(uint256[] calldata tokenIds, address to) external nonReentrant {
        uint256 totalTransfers = tokenIds.length;
        require(totalTransfers > 0 && totalTransfers <= 20, "Invalid transfer count");
        require(to != address(0), "Invalid recipient");

        for (uint256 i = 0; i < totalTransfers; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not token owner");
            _transfer(msg.sender, to, tokenIds[i]);
        }

        emit BulkTransferExecuted(msg.sender, to, tokenIds);
    }

    /// @notice Bulk update metadata URIs for multiple NFTs (owner only)
    /// @param updates Array of metadata update parameters (up to 50 updates per transaction)
    function bulkUpdateMetadata(BulkMetadataUpdate[] calldata updates) external onlyOwner {
        uint256 totalUpdates = updates.length;
        require(totalUpdates > 0 && totalUpdates <= 50, "Invalid update count");

        uint256[] memory tokenIds = new uint256[](totalUpdates);
        string[] memory newURIs = new string[](totalUpdates);

        for (uint256 i = 0; i < totalUpdates; i++) {
            BulkMetadataUpdate calldata updateData = updates[i];
            require(_ownerOf(updateData.tokenId) != address(0), "Token does not exist");

            _setTokenURI(updateData.tokenId, updateData.newURI);
            tokenIds[i] = updateData.tokenId;
            newURIs[i] = updateData.newURI;
        }

        emit BulkMetadataUpdated(tokenIds, newURIs);
    }

    /// @notice Bulk mint with custom URIs (owner only, for airdrops/giveaways)
    /// @param recipients Array of recipient addresses
    /// @param customURIs Array of custom token URIs
    function bulkMintWithURIs(address[] calldata recipients, string[] calldata customURIs)
        external
        payable
        onlyOwner
        nonReentrant
    {
        uint256 totalMints = recipients.length;
        require(totalMints > 0 && totalMints <= 50, "Invalid mint count");
        require(totalMints == customURIs.length, "Array length mismatch");
        require(_availableTokenIds.length >= totalMints, "Not enough NFTs available");

        uint256 totalCost = MINT_PRICE * totalMints;
        require(msg.value >= totalCost, "Insufficient payment");

        for (uint256 i = 0; i < totalMints; i++) {
            uint256 randomIndex = _getRandomIndex();
            uint256 tokenId = _availableTokenIds[randomIndex];
            _removeTokenIdAtIndex(randomIndex);

            _safeMint(recipients[i], tokenId);
            _setTokenURI(tokenId, customURIs[i]);

            emit NFTMinted(recipients[i], tokenId);
        }

        emit BulkMintExecuted(msg.sender, totalMints, totalCost);

        // Refund excess payment
        if (msg.value > totalCost) {
            (bool success,) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(success, "Refund failed");
        }
    }

    /// @notice Bulk approve multiple NFTs for transfer (gas optimization)
    /// @param operators Array of operator addresses
    /// @param approved Array of approval booleans
    function bulkSetApprovalForAll(address[] calldata operators, bool[] calldata approved) external {
        uint256 totalOperations = operators.length;
        require(totalOperations > 0 && totalOperations <= 20, "Invalid operation count");
        require(totalOperations == approved.length, "Array length mismatch");

        for (uint256 i = 0; i < totalOperations; i++) {
            setApprovalForAll(operators[i], approved[i]);
        }
    }

    /// @notice Get bulk operation limits
    /// @return maxBulkTransfers Maximum transfers per bulk transaction
    /// @return maxBulkUpdates Maximum metadata updates per bulk transaction
    /// @return maxBulkMints Maximum mints per bulk transaction
    function getBulkLimits()
        external
        pure
        returns (uint256 maxBulkTransfers, uint256 maxBulkUpdates, uint256 maxBulkMints)
    {
        return (20, 50, 50);
    }

    /// @notice Estimate gas for bulk operations
    /// @param operationCount Number of operations
    /// @param operationType 0=transfer, 1=metadata update, 2=mint, 3=approval
    /// @return estimatedGas Approximate gas cost
    function estimateBulkGas(uint256 operationCount, uint256 operationType)
        external
        pure
        returns (uint256 estimatedGas)
    {
        require(operationCount > 0, "Invalid count");

        uint256 baseGas = 21000;
        uint256 perOperationGas;

        if (operationType == 0) {
            // Bulk transfers
            perOperationGas = operationCount <= 20 ? 50000 : 60000;
            require(operationCount <= 20, "Too many transfers");
        } else if (operationType == 1) {
            // Metadata updates
            perOperationGas = 35000;
            require(operationCount <= 50, "Too many updates");
        } else if (operationType == 2) {
            // Bulk mints
            perOperationGas = 75000;
            require(operationCount <= 50, "Too many mints");
        } else if (operationType == 3) {
            // Approval operations
            perOperationGas = 25000;
            require(operationCount <= 20, "Too many approvals");
        } else {
            revert("Invalid operation type");
        }

        return baseGas + (perOperationGas * operationCount);
    }

    /*//////////////////////////////////////////////////////////////
                           HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Extract token IDs from bulk transfer array
    function _extractTokenIds(BulkTransfer[] calldata transfers) private pure returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](transfers.length);
        for (uint256 i = 0; i < transfers.length; i++) {
            tokenIds[i] = transfers[i].tokenId;
        }
        return tokenIds;
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
