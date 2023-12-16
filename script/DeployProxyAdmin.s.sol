// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {TokenizedVickeryAuctionProxyAdmin} from "../src/TokenizedVickreyAuctionProxyAdmin.sol";

contract DeployProxyAdmin is Script {
    TokenizedVickeryAuctionProxyAdmin proxyAdmin;

    function run() external returns (TokenizedVickeryAuctionProxyAdmin) {
        vm.startBroadcast();

        proxyAdmin = new TokenizedVickeryAuctionProxyAdmin(msg.sender);

        vm.stopBroadcast();

        return proxyAdmin;
    }
}
