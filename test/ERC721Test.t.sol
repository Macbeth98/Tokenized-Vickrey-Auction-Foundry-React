// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {NEUAuctionNFT} from "../src/ERC721/NEUAuctionNFT.sol";
import {NeoNEUAuctionNFT} from "../src/ERC721/NeoNEUAuctionNFT.sol";

contract ERC721Test is Test {
    NEUAuctionNFT neu;
    NeoNEUAuctionNFT nneu;

    address public constant OWNER = address(0x123);

    function setUp() public {
        vm.startPrank(OWNER);
        neu = new NEUAuctionNFT();
        nneu = new NeoNEUAuctionNFT();
        vm.stopPrank();
    }

    function testERC721Tokens() public {
        assertEq(neu.name(), "NEU Auction");
        assertEq(neu.symbol(), "NEU");

        assertEq(nneu.name(), "Neo NEU Auction");
        assertEq(nneu.symbol(), "NNEU");
    }

    function testOwnerBalance() public {
        assertEq(neu.balanceOf(OWNER), 1);
        assertEq(nneu.balanceOf(OWNER), 1);
    }

    function testMint() public {
        vm.startPrank(OWNER);
        neu.mint(OWNER, 2);
        assertEq(neu.balanceOf(OWNER), 2);
        assertEq(neu.ownerOf(1), OWNER);
        assertEq(neu.ownerOf(2), OWNER);

        nneu.mint(OWNER, 2);
        assertEq(nneu.balanceOf(OWNER), 2);
        assertEq(nneu.ownerOf(1), OWNER);
        assertEq(nneu.ownerOf(2), OWNER);
    }
}
