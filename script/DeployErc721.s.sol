// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {NEUAuctionNFT} from "../src/ERC721/NEUAuctionNFT.sol";
import {NeoNEUAuctionNFT} from "../src/ERC721/NeoNEUAuctionNFT.sol";

contract DeployErc721 is Script {
    NEUAuctionNFT neuAuctionNFT;
    NeoNEUAuctionNFT neoNEUAuctionNFT;

    function run() external returns (NEUAuctionNFT, NeoNEUAuctionNFT) {
        vm.startBroadcast();

        neuAuctionNFT = new NEUAuctionNFT();
        neoNEUAuctionNFT = new NeoNEUAuctionNFT();

        vm.stopBroadcast();

        return (neuAuctionNFT, neoNEUAuctionNFT);
    }
}
