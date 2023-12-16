// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {MTRToken} from "../src/ERC20/MTRToken.sol";
import {TRMToken} from "../src/ERC20/TRMToken.sol";
import {RMTToken} from "../src/ERC20/RMTToken.sol";

contract DeployErc20 is Script {
    MTRToken mtr;
    TRMToken trm;
    RMTToken rmt;

    function run() external returns (MTRToken, TRMToken, RMTToken) {
        vm.startBroadcast();

        mtr = new MTRToken();
        trm = new TRMToken();
        rmt = new RMTToken();

        vm.stopBroadcast();

        return (mtr, trm, rmt);
    }
}
