// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {TokenizedVickeryAuctionV2} from "../src/TokenizedVickeryAuctionV2.sol";

contract DeployAuction is Script {
    TokenizedVickeryAuctionV2 auction;

    function run() external returns (TokenizedVickeryAuctionV2) {
        vm.startBroadcast();

        auction = new TokenizedVickeryAuctionV2();

        vm.stopBroadcast();

        return auction;
    }
}
