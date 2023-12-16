// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

abstract contract ERC20Test is Test {
    IERC20 public erc20Token;
    string public name;
    string public symbol;

    address public constant OWNER = address(0x123);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function testERC20Tokens() public {
        ERC20Mock mock = ERC20Mock(address(erc20Token));
        assertEq(mock.name(), name);
        assertEq(mock.symbol(), symbol);
        assertEq(mock.decimals(), 0);
    }

    function testOwnerBalance() public {
        assertEq(erc20Token.balanceOf(OWNER), 1000);
        assertEq(erc20Token.totalSupply(), 1000);
    }

    function testMint() public {
        ERC20Mock mock = ERC20Mock(address(erc20Token));
        mock.mint(OWNER, 100);
        assertEq(erc20Token.balanceOf(OWNER), 1100);
        assertEq(erc20Token.totalSupply(), 1100);
    }

    function testMintLimit() public {
        ERC20Mock mock = ERC20Mock(address(erc20Token));
        mock.mint(OWNER, 1001);
        assertEq(erc20Token.balanceOf(OWNER), 2000);
        assertEq(erc20Token.totalSupply(), 2000);
    }
}
