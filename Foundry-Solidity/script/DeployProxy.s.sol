// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {TokenizedVickeryAuctionProxy} from "../src/TokenizedVickeryAuctionProxy.sol";

contract DeployProxy is Script {
    TokenizedVickeryAuctionProxy proxy;

    address constant logic = 0xbF0Dd758786d40D081480f9198Db3887E25b4684;
    address constant admin = 0x8BfEA5a80255eB728256A3e355c1106c70281bc7;
    bytes constant data = hex"";

    function run() external returns (TokenizedVickeryAuctionProxy) {
        vm.startBroadcast();

        proxy = new TokenizedVickeryAuctionProxy(logic, admin, data);

        vm.stopBroadcast();

        return proxy;
    }
}
