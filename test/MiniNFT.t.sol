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
}
