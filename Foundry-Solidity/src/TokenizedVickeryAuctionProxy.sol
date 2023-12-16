// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy, ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TokenizedVickeryAuctionProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}

    function implementation() external view returns (address) {
        return _implementation();
    }

    function admin() external view returns (address) {
        return _proxyAdmin();
    }

    receive() external payable {
        _fallback();
    }
}
