// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {TokenizedVickeryAuctionTest} from "./TokenizedVickeryAuction.t.sol";
import {TokenizedVickeryAuctionV2} from "../src/TokenizedVickeryAuctionV2.sol";

contract TokenizedVickeryAuctionV2Test is TokenizedVickeryAuctionTest {
    TokenizedVickeryAuctionV2 public tvAuction2;

    address public constant OWNER = address(0xabc);
    address public constant SELLER_BLACKLISTED = address(0x123);

    function setUp() public virtual override {
        vm.prank(OWNER);
        tvAuction2 = new TokenizedVickeryAuctionV2();
        super.setUp();
        tvAuction = tvAuction2;
        vm.deal(OWNER, 1 ether);

        giveERC721Approval(SELLER, address(tvAuction2));
    }

    function testBlacklistSeller() public {
        vm.prank(OWNER);
        tvAuction2.blacklistSeller(SELLER_BLACKLISTED);
        assertEq(tvAuction2.isBlacklistedSeller(SELLER_BLACKLISTED), true);
    }

    function testCreateAuctionCannotBeDoneByBlacklistedSeller() public {
        vm.prank(OWNER);
        tvAuction2.blacklistSeller(SELLER_BLACKLISTED);

        vm.prank(SELLER_BLACKLISTED);
        vm.expectRevert(
            TokenizedVickeryAuctionV2.TVA2__BLACKLISTED_SELLER.selector
        );
        tvAuction2.createAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auctionParams.erc20Token,
            auctionParams.startTime,
            auctionParams.bidPeriod,
            auctionParams.revealPeriod,
            auctionParams.reservePrice
        );
    }

    function testCreateAuctionCanBeDoneByNonBlacklistedSeller() public {
        vm.prank(OWNER);
        tvAuction2.blacklistSeller(SELLER_BLACKLISTED);

        vm.prank(SELLER);
        tvAuction2.createAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auctionParams.erc20Token,
            auctionParams.startTime,
            auctionParams.bidPeriod,
            auctionParams.revealPeriod,
            auctionParams.reservePrice
        );
    }
}
