// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {ERC20Test} from "./ERC20Test.t.sol";

import {RMTToken} from "../../src/ERC20/RMTToken.sol";

contract RMTTokenTest is Test {
    // constructor() ERC20Test("RMTToken", "RMT") {}

    RMTToken erc20Token;

    address public constant OWNER = address(0x123);

    function setUp() public {
        vm.prank(OWNER);
        erc20Token = new RMTToken();
    }

    function testERC20Tokens() public {
        assertEq(erc20Token.name(), "RMTToken");
        assertEq(erc20Token.symbol(), "RMT");
        assertEq(erc20Token.decimals(), 0);
    }

    function testOwnerBalance() public {
        assertEq(erc20Token.balanceOf(OWNER), 1000);
        assertEq(erc20Token.totalSupply(), 1000);
    }

    function testMint() public {
        erc20Token.mint(OWNER, 100);
        assertEq(erc20Token.balanceOf(OWNER), 1100);
        assertEq(erc20Token.totalSupply(), 1100);
    }

    function testMintLimit() public {
        erc20Token.mint(OWNER, 1001);
        assertEq(erc20Token.balanceOf(OWNER), 2000);
        assertEq(erc20Token.totalSupply(), 2000);
    }
}
