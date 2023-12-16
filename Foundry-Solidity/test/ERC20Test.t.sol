// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {MTRToken} from "../src/ERC20/MTRToken.sol";
import {TRMToken} from "../src/ERC20/TRMToken.sol";
import {RMTToken} from "../src/ERC20/RMTToken.sol";

contract ERC20Test is Test {
    MTRToken mtr;
    TRMToken trm;
    RMTToken rmt;

    address public constant OWNER = address(0x123);

    function setUp() public {
        vm.startPrank(OWNER);
        mtr = new MTRToken();
        trm = new TRMToken();
        rmt = new RMTToken();
        vm.stopPrank();
    }

    function testERC20Tokens() public {
        assertEq(mtr.name(), "MTRToken");
        assertEq(mtr.symbol(), "MTR");
        assertEq(mtr.decimals(), 0);

        assertEq(trm.name(), "TRMToken");
        assertEq(trm.symbol(), "TRM");
        assertEq(trm.decimals(), 0);

        assertEq(rmt.name(), "RMTToken");
        assertEq(rmt.symbol(), "RMT");
        assertEq(rmt.decimals(), 0);
    }

    function testOwnerBalance() public {
        assertEq(mtr.balanceOf(OWNER), 1000);
        assertEq(trm.balanceOf(OWNER), 1000);
        assertEq(rmt.balanceOf(OWNER), 1000);

        assertEq(mtr.totalSupply(), 1000);
        assertEq(trm.totalSupply(), 1000);
        assertEq(rmt.totalSupply(), 1000);
    }

    function testMint() public {
        vm.startPrank(OWNER);
        mtr.mint(OWNER, 100);
        assertEq(mtr.balanceOf(OWNER), 1100);
        assertEq(mtr.totalSupply(), 1100);

        trm.mint(OWNER, 100);
        assertEq(trm.balanceOf(OWNER), 1100);
        assertEq(trm.totalSupply(), 1100);

        rmt.mint(OWNER, 100);
        assertEq(rmt.balanceOf(OWNER), 1100);
        assertEq(rmt.totalSupply(), 1100);
        vm.stopPrank();
    }

    function testMintLimit() public {
        vm.startPrank(OWNER);
        mtr.mint(OWNER, 1001);
        assertEq(mtr.balanceOf(OWNER), 2000);
        assertEq(mtr.totalSupply(), 2000);

        trm.mint(OWNER, 1001);
        assertEq(trm.balanceOf(OWNER), 2000);
        assertEq(trm.totalSupply(), 2000);

        rmt.mint(OWNER, 1001);
        assertEq(rmt.balanceOf(OWNER), 2000);
        assertEq(rmt.totalSupply(), 2000);
        vm.stopPrank();
    }
}
