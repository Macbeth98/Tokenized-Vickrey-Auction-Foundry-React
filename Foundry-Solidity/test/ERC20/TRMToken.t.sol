// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ERC20Test} from "./ERC20Test.t.sol";

import {TRMToken} from "../../src/ERC20/TRMToken.sol";

contract TRMTokenTest is ERC20Test {
    constructor() ERC20Test("TRMToken", "TRM") {}

    function setUp() public {
        vm.prank(OWNER);
        erc20Token = new TRMToken();
    }
}
