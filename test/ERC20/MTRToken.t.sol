// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ERC20Test} from "./ERC20Test.t.sol";

import {MTRToken} from "../../src/ERC20/MTRToken.sol";

contract MTRTokenTest is ERC20Test {
    constructor() ERC20Test("MTRToken", "MTR") {}

    function setUp() public {
        vm.prank(OWNER);
        erc20Token = new MTRToken();
    }
}
