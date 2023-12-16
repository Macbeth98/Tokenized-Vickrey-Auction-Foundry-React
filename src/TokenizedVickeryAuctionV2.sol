// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {TokenizedVickeryAuction} from "./TokenizedVickeryAuction.sol";

contract TokenizedVickeryAuctionV2 is TokenizedVickeryAuction {
    error TVA2__BLACKLISTED_SELLER();
    error TVA2__ONLY_OWNER();

    address public immutable owner;

    mapping(address => bool) public isBlacklistedSeller;

    constructor() TokenizedVickeryAuction() {
        owner = msg.sender;
    }

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        address erc20Token,
        uint32 startTime,
        uint32 bidPeriod,
        uint32 revealPeriod,
        uint96 reservePrice
    ) external override {
        if (isBlacklistedSeller[msg.sender]) {
            revert TVA2__BLACKLISTED_SELLER();
        }
        super._createAuction(
            tokenContract,
            tokenId,
            erc20Token,
            startTime,
            bidPeriod,
            revealPeriod,
            reservePrice
        );
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert TVA2__ONLY_OWNER();
        }
        _;
    }

    function blacklistSeller(address seller) external onlyOwner {
        isBlacklistedSeller[seller] = true;
    }
}
