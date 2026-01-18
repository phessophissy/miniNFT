// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MiniNFT.sol";

contract MiniNFTTest is Test {
    MiniNFT public nft;
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    // Allow contract to receive ETH
    receive() external payable {}

    function setUp() public {
        nft = new MiniNFT("MiniNFT", "MNFT", "ipfs://test/");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
    }

    function testInitialState() public view {
        assertEq(nft.MAX_SUPPLY(), 505);
        assertEq(nft.MINT_PRICE(), 0.00001 ether);
        assertEq(nft.remainingSupply(), 505);
        assertEq(nft.totalSupply(), 0);
    }

    function testMint() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.remainingSupply(), 504);
        assertEq(nft.balanceOf(user1), 1);
    }

    function testMintBatch() public {
        vm.prank(user1);
        nft.mintBatch{value: 0.00005 ether}(5);

        assertEq(nft.totalSupply(), 5);
        assertEq(nft.remainingSupply(), 500);
        assertEq(nft.balanceOf(user1), 5);
    }

    function testMintInsufficientPayment() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient payment");
        nft.mint{value: 0.000009 ether}();
    }

    function testMintBatchMaxLimit() public {
        vm.prank(user1);
        vm.expectRevert("Max 10 NFTs per batch");
        nft.mintBatch{value: 0.00011 ether}(11);
    }

    function testWithdraw() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        uint256 balanceBefore = address(owner).balance;
        nft.withdraw();
        uint256 balanceAfter = address(owner).balance;

        assertEq(balanceAfter - balanceBefore, 0.00001 ether);
    }

    function testSetBaseURI() public {
        nft.setBaseURI("ipfs://newuri/");
        assertEq(nft.baseTokenURI(), "ipfs://newuri/");
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        vm.prank(user1);
        vm.expectRevert();
        nft.withdraw();
    }

    /*//////////////////////////////////////////////////////////////
                           PAUSABLE TESTS
    //////////////////////////////////////////////////////////////*/

    function testPause() public {
        nft.pause();
        assertTrue(nft.paused());
    }

    function testUnpause() public {
        nft.pause();
        assertTrue(nft.paused());

        nft.unpause();
        assertFalse(nft.paused());
    }

    function testOnlyOwnerCanPause() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.pause();
    }

    function testOnlyOwnerCanUnpause() public {
        nft.pause();

        vm.prank(user1);
        vm.expectRevert();
        nft.unpause();
    }

    function testMintWhenPaused() public {
        nft.pause();

        vm.prank(user1);
        vm.expectRevert("Pausable: paused");
        nft.mint{value: 0.00001 ether}();
    }

    function testMintBatchWhenPaused() public {
        nft.pause();

        vm.prank(user1);
        vm.expectRevert("Pausable: paused");
        nft.mintBatch{value: 0.00005 ether}(5);
    }

    function testBulkMintWithURIsWhenPaused() public {
        nft.pause();

        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        string[] memory customURIs = new string[](1);
        customURIs[0] = "ipfs://custom/";

        vm.expectRevert("Pausable: paused");
        nft.bulkMintWithURIs{value: 0.00001 ether}(recipients, customURIs);
    }

    /*//////////////////////////////////////////////////////////////
                           BURN TESTS
    //////////////////////////////////////////////////////////////*/

    function testBurn() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit MiniNFT.NFTBurned(user1, 1);
        nft.burn(1);

        assertEq(nft.totalSupply(), 0);
        assertEq(nft.balanceOf(user1), 0);
    }

    function testBurnNotOwner() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        vm.prank(user2);
        vm.expectRevert("Not token owner");
        nft.burn(1);
    }

    function testBurnNonExistentToken() public {
        vm.prank(user1);
        vm.expectRevert("Not token owner");
        nft.burn(999);
    }

    /*//////////////////////////////////////////////////////////////
                           BULK OPERATIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function testBulkTransfer() public {
        // Mint some NFTs first
        vm.startPrank(user1);
        nft.mint{value: 0.00001 ether}();
        nft.mint{value: 0.00001 ether}();
        nft.mint{value: 0.00001 ether}();
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1; // Assuming these are the minted token IDs
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        // Test bulk transfer to same recipient
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit MiniNFT.BulkTransferExecuted(user1, user2, tokenIds);
        nft.bulkTransferToRecipient(tokenIds, user2);

        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 3);
    }

    function testBulkTransferMixedRecipients() public {
        // Mint NFTs
        vm.startPrank(user1);
        nft.mint{value: 0.00001 ether}();
        nft.mint{value: 0.00001 ether}();
        vm.stopPrank();

        MiniNFT.BulkTransfer[] memory transfers = new MiniNFT.BulkTransfer[](2);
        transfers[0] = MiniNFT.BulkTransfer({tokenId: 1, to: user2});
        transfers[1] = MiniNFT.BulkTransfer({tokenId: 2, to: address(0x3)});

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit MiniNFT.BulkTransferExecuted(user1, address(0), _getTokenIds(transfers));
        nft.bulkTransfer(transfers);

        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.balanceOf(address(0x3)), 1);
    }

    function testBulkTransferExceedsLimit() public {
        vm.startPrank(user1);
        for (uint256 i = 0; i < 21; i++) {
            nft.mint{value: 0.00001 ether}();
        }
        vm.stopPrank();

        MiniNFT.BulkTransfer[] memory transfers = new MiniNFT.BulkTransfer[](21);
        for (uint256 i = 0; i < 21; i++) {
            transfers[i] = MiniNFT.BulkTransfer({tokenId: i + 1, to: user2});
        }

        vm.prank(user1);
        vm.expectRevert("Invalid transfer count");
        nft.bulkTransfer(transfers);
    }

    function testBulkTransferNotOwner() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        MiniNFT.BulkTransfer[] memory transfers = new MiniNFT.BulkTransfer[](1);
        transfers[0] = MiniNFT.BulkTransfer({tokenId: 1, to: user2});

        vm.prank(user2);
        vm.expectRevert("Not token owner");
        nft.bulkTransfer(transfers);
    }

    function testBulkTransferToRecipientExceedsLimit() public {
        vm.startPrank(user1);
        for (uint256 i = 0; i < 21; i++) {
            nft.mint{value: 0.00001 ether}();
        }
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](21);
        for (uint256 i = 0; i < 21; i++) {
            tokenIds[i] = i + 1;
        }

        vm.prank(user1);
        vm.expectRevert("Invalid transfer count");
        nft.bulkTransferToRecipient(tokenIds, user2);
    }

    function testBulkUpdateMetadata() public {
        // Mint NFT first
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        MiniNFT.BulkMetadataUpdate[] memory updates = new MiniNFT.BulkMetadataUpdate[](1);
        updates[0] = MiniNFT.BulkMetadataUpdate({
            tokenId: 1,
            newURI: "ipfs://new-metadata/"
        });

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        string[] memory newURIs = new string[](1);
        newURIs[0] = "ipfs://new-metadata/";

        vm.expectEmit(true, false, false, true);
        emit MiniNFT.BulkMetadataUpdated(tokenIds, newURIs);
        nft.bulkUpdateMetadata(updates);

        assertEq(nft.tokenURI(1), "ipfs://new-metadata/1");
    }

    function testBulkUpdateMetadataMultiple() public {
        // Mint multiple NFTs
        vm.startPrank(user1);
        nft.mint{value: 0.00001 ether}();
        nft.mint{value: 0.00001 ether}();
        nft.mint{value: 0.00001 ether}();
        vm.stopPrank();

        MiniNFT.BulkMetadataUpdate[] memory updates = new MiniNFT.BulkMetadataUpdate[](3);
        updates[0] = MiniNFT.BulkMetadataUpdate({tokenId: 1, newURI: "ipfs://custom1/"});
        updates[1] = MiniNFT.BulkMetadataUpdate({tokenId: 2, newURI: "ipfs://custom2/"});
        updates[2] = MiniNFT.BulkMetadataUpdate({tokenId: 3, newURI: "ipfs://custom3/"});

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        string[] memory newURIs = new string[](3);
        newURIs[0] = "ipfs://custom1/";
        newURIs[1] = "ipfs://custom2/";
        newURIs[2] = "ipfs://custom3/";

        vm.expectEmit(true, false, false, true);
        emit MiniNFT.BulkMetadataUpdated(tokenIds, newURIs);
        nft.bulkUpdateMetadata(updates);
    }

    function testBulkUpdateMetadataOnlyOwner() public {
        vm.prank(user1);
        nft.mint{value: 0.00001 ether}();

        MiniNFT.BulkMetadataUpdate[] memory updates = new MiniNFT.BulkMetadataUpdate[](1);
        updates[0] = MiniNFT.BulkMetadataUpdate({tokenId: 1, newURI: "ipfs://new/"});

        vm.prank(user1);
        vm.expectRevert();
        nft.bulkUpdateMetadata(updates);
    }

    function testBulkUpdateMetadataExceedsLimit() public {
        MiniNFT.BulkMetadataUpdate[] memory updates = new MiniNFT.BulkMetadataUpdate[](51);
        for (uint256 i = 0; i < 51; i++) {
            updates[i] = MiniNFT.BulkMetadataUpdate({tokenId: 1, newURI: "ipfs://test/"});
        }

        vm.expectRevert("Invalid update count");
        nft.bulkUpdateMetadata(updates);
    }

    function testBulkMintWithURIs() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        string[] memory customURIs = new string[](2);
        customURIs[0] = "ipfs://custom-nft-1/";
        customURIs[1] = "ipfs://custom-nft-2/";

        vm.expectEmit(true, false, false, true);
        emit MiniNFT.BulkMintExecuted(owner, 2, 0.00002 ether);
        nft.bulkMintWithURIs{value: 0.00002 ether}(recipients, customURIs);

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.totalSupply(), 2);
        assertEq(nft.remainingSupply(), 503);
    }

    function testBulkMintWithURIsOnlyOwner() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        string[] memory customURIs = new string[](1);
        customURIs[0] = "ipfs://custom/";

        vm.prank(user1);
        vm.expectRevert();
        nft.bulkMintWithURIs{value: 0.00001 ether}(recipients, customURIs);
    }

    function testBulkMintWithURIsArrayMismatch() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        string[] memory customURIs = new string[](1); // Wrong length
        customURIs[0] = "ipfs://custom/";

        vm.expectRevert("Array length mismatch");
        nft.bulkMintWithURIs{value: 0.00002 ether}(recipients, customURIs);
    }

    function testBulkMintWithURIsExceedsLimit() public {
        address[] memory recipients = new address[](51);
        string[] memory customURIs = new string[](51);

        for (uint256 i = 0; i < 51; i++) {
            recipients[i] = user1;
            customURIs[i] = "ipfs://test/";
        }

        vm.expectRevert("Invalid mint count");
        nft.bulkMintWithURIs{value: 0.00051 ether}(recipients, customURIs);
    }

    function testBulkSetApprovalForAll() public {
        address[] memory operators = new address[](2);
        operators[0] = user1;
        operators[1] = user2;

        bool[] memory approved = new bool[](2);
        approved[0] = true;
        approved[1] = false;

        vm.prank(user1);
        nft.bulkSetApprovalForAll(operators, approved);

        assertTrue(nft.isApprovedForAll(user1, operators[0]));
        assertFalse(nft.isApprovedForAll(user1, operators[1]));
    }

    function testBulkSetApprovalForAllArrayMismatch() public {
        address[] memory operators = new address[](2);
        operators[0] = user1;
        operators[1] = user2;

        bool[] memory approved = new bool[](1); // Wrong length
        approved[0] = true;

        vm.prank(user1);
        vm.expectRevert("Array length mismatch");
        nft.bulkSetApprovalForAll(operators, approved);
    }

    function testGetBulkLimits() public view {
        (uint256 maxTransfers, uint256 maxUpdates, uint256 maxMints) = nft.getBulkLimits();
        assertEq(maxTransfers, 20);
        assertEq(maxUpdates, 50);
        assertEq(maxMints, 50);
    }

    function testEstimateBulkGas() public view {
        // Test transfer estimation
        uint256 gasEstimate = nft.estimateBulkGas(5, 0); // 5 transfers
        assertGt(gasEstimate, 21000);

        // Test metadata update estimation
        gasEstimate = nft.estimateBulkGas(10, 1); // 10 updates
        assertGt(gasEstimate, 21000);

        // Test mint estimation
        gasEstimate = nft.estimateBulkGas(3, 2); // 3 mints
        assertGt(gasEstimate, 21000);

        // Test approval estimation
        gasEstimate = nft.estimateBulkGas(5, 3); // 5 approvals
        assertGt(gasEstimate, 21000);
    }

    function testEstimateBulkGasInvalidType() public {
        vm.expectRevert("Invalid operation type");
        nft.estimateBulkGas(5, 99);
    }

    function testEstimateBulkGasExceedsLimits() public {
        vm.expectRevert("Too many transfers");
        nft.estimateBulkGas(21, 0);

        vm.expectRevert("Too many updates");
        nft.estimateBulkGas(51, 1);

        vm.expectRevert("Too many mints");
        nft.estimateBulkGas(51, 2);

        vm.expectRevert("Too many approvals");
        nft.estimateBulkGas(21, 3);
    }

    /*//////////////////////////////////////////////////////////////
                           HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getTokenIds(MiniNFT.BulkTransfer[] memory transfers) private pure returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](transfers.length);
        for (uint256 i = 0; i < transfers.length; i++) {
            tokenIds[i] = transfers[i].tokenId;
        }
        return tokenIds;
    }
}
