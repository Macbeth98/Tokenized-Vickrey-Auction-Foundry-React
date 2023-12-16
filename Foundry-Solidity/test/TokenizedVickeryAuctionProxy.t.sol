// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TokenizedVickeryAuction} from "../src/TokenizedVickeryAuction.sol";
import {TokenizedVickeryAuctionV2} from "../src/TokenizedVickeryAuctionV2.sol";
import {TokenizedVickeryAuctionProxy, ITransparentUpgradeableProxy, ProxyAdmin} from "../src/TokenizedVickeryAuctionProxy.sol";
import {TokenizedVickeryAuctionTest} from "./TokenizedVickeryAuction.t.sol";
import {TokenizedVickeryAuctionV2Test} from "./TokenizedVickeryAuctionV2.t.sol";

contract TokenizedVickeryAuctionProxyTest is TokenizedVickeryAuctionTest {
    TokenizedVickeryAuctionProxy public tvAuctionProxy;
    ITransparentUpgradeableProxy public ItvAuctionProxy;

    address public implementation;

    address public constant OWNER = address(0xabc);

    function setUp() public override {
        super.setUp();

        vm.deal(OWNER, 1 ether);

        vm.prank(OWNER);
        tvAuctionProxy = new TokenizedVickeryAuctionProxy(
            address(tvAuction),
            OWNER,
            ""
        );

        implementation = address(tvAuction);

        tvAuction = TokenizedVickeryAuction(address(tvAuctionProxy));

        ItvAuctionProxy = ITransparentUpgradeableProxy(address(tvAuctionProxy));

        giveERC721Approval(SELLER, address(tvAuction));
    }

    function testProxyImplementation() public {
        assertEq(tvAuctionProxy.implementation(), implementation);
    }

    function testProxyAdmin() public {
        address proxyAdmin = tvAuctionProxy.admin();

        assertEq(ProxyAdmin(proxyAdmin).owner(), OWNER);
    }

    function testChangeAdmin() public {
        address proxyAdmin = tvAuctionProxy.admin();

        vm.prank(OWNER);
        ProxyAdmin(proxyAdmin).transferOwnership(address(this));

        assertEq(ProxyAdmin(proxyAdmin).owner(), address(this));
    }

    function testProxyUpgradeToAndCall() public {
        TokenizedVickeryAuctionV2 tvAuction2 = new TokenizedVickeryAuctionV2();

        address proxy = tvAuctionProxy.admin();

        vm.prank(OWNER);
        ProxyAdmin(proxy).upgradeAndCall(
            ItvAuctionProxy,
            address(tvAuction2),
            ""
        );

        assertEq(tvAuctionProxy.implementation(), address(tvAuction2));
    }
}

contract TokenizedVickeryAuctionV2ProxyTest is TokenizedVickeryAuctionV2Test {
    TokenizedVickeryAuctionProxy public tvAuctionProxy;
    ITransparentUpgradeableProxy public ItvAuctionProxy;

    address public implementation;

    function setUp() public override {
        super.setUp();

        vm.prank(OWNER);
        tvAuctionProxy = new TokenizedVickeryAuctionProxy(
            address(tvAuction),
            OWNER,
            ""
        );

        implementation = address(tvAuction);

        tvAuction = TokenizedVickeryAuction(address(tvAuctionProxy));

        ItvAuctionProxy = ITransparentUpgradeableProxy(address(tvAuctionProxy));

        giveERC721Approval(SELLER, address(tvAuctionProxy));

        // change to v2
        address proxy = tvAuctionProxy.admin();
        vm.prank(OWNER);
        ProxyAdmin(proxy).upgradeAndCall(
            ItvAuctionProxy,
            address(tvAuction2),
            ""
        );

        implementation = address(tvAuction2);

        tvAuction2 = TokenizedVickeryAuctionV2(address(tvAuctionProxy));
    }

    function testProxyImplementation() public {
        assertEq(tvAuctionProxy.implementation(), implementation);
    }

    function testProxyAdmin() public {
        address proxyAdmin = tvAuctionProxy.admin();

        assertEq(ProxyAdmin(proxyAdmin).owner(), OWNER);
    }
}
