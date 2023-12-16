// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC721Mock} from "../src/ERC721Mock.sol";
import {TokenizedVickeryAuction} from "../src/TokenizedVickeryAuction.sol";

contract TokenizedVickeryAuctionTest is Test {
    bytes20 private constant BID_REVEALED = bytes20("Bid Revealed");

    TokenizedVickeryAuction public tvAuction;

    ERC20Mock public erc20Mock;

    ERC721Mock public erc721Mock;

    struct AuctionParams {
        uint256 tokenId;
        address tokenContract;
        uint32 startTime;
        uint32 bidPeriod;
        uint32 revealPeriod;
        uint96 reservePrice;
        address erc20Token;
    }

    AuctionParams public auctionParams;

    address public constant SELLER = address(0xa1);
    address public constant BUYER1 = address(0xb1);
    address public constant BUYER2 = address(0xb2);

    function setUp() public virtual {
        erc20Mock = new ERC20Mock();
        erc721Mock = new ERC721Mock();
        tvAuction = new TokenizedVickeryAuction();

        erc721Mock.mint(SELLER, 1);
        erc721Mock.mint(SELLER, 2);

        erc20Mock.mint(BUYER1, 1000);
        erc20Mock.mint(BUYER2, 1000);

        auctionParams = AuctionParams({
            tokenId: 1,
            tokenContract: address(erc721Mock),
            startTime: uint32(block.timestamp),
            bidPeriod: 100,
            revealPeriod: 100,
            reservePrice: 100,
            erc20Token: address(erc20Mock)
        });

        vm.deal(SELLER, 1 ether);
        vm.deal(BUYER1, 1 ether);
        vm.deal(BUYER2, 1 ether);

        giveERC721Approval(SELLER, address(tvAuction));
    }

    function giveERC721Approval(address owner, address spender) internal {
        vm.prank(owner);
        erc721Mock.approve(spender, auctionParams.tokenId);
    }

    function giveERC20Approval(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        vm.prank(owner);
        erc20Mock.approve(spender, amount);
    }

    function createAuction(address seller) internal {
        vm.prank(seller);
        tvAuction.createAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auctionParams.erc20Token,
            auctionParams.startTime,
            auctionParams.bidPeriod,
            auctionParams.revealPeriod,
            auctionParams.reservePrice
        );
    }

    function giveApprovalAndCreateAuction(address seller) internal {
        giveERC721Approval(seller, address(tvAuction));
        createAuction(seller);
    }

    function getAuction()
        internal
        view
        returns (TokenizedVickeryAuction.Auction memory auction)
    {
        auction = tvAuction.getAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );
    }

    function getCommitment(
        bytes32 nonce,
        uint96 bidValue,
        uint64 auctionIndex
    ) public view returns (bytes20) {
        return
            bytes20(
                keccak256(
                    abi.encode(
                        nonce,
                        bidValue,
                        auctionParams.tokenContract,
                        auctionParams.tokenId,
                        auctionIndex
                    )
                )
            );
    }

    function testCreateAuction() public {
        createAuction(SELLER);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.status, true);
        assertEq(auction.seller, SELLER);
        assertEq(auction.startTime, auctionParams.startTime);
        assertEq(
            auction.endOfBiddingPeriod,
            auctionParams.startTime + auctionParams.bidPeriod
        );
        assertEq(
            auction.endOfRevealPeriod,
            auctionParams.startTime +
                auctionParams.bidPeriod +
                auctionParams.revealPeriod
        );
        assertEq(auction.highestBid, auctionParams.reservePrice);
        assertEq(auction.secondHighestBid, auctionParams.reservePrice);
        assertEq(auction.highestBidder, address(0));
        assertEq(auction.index, 1);
        assertEq(auction.numUnrevealedBids, 0);
        assertEq(auction.highestBid, auctionParams.reservePrice);
        assertEq(auction.secondHighestBid, auctionParams.reservePrice);

        assertEq(erc721Mock.ownerOf(auctionParams.tokenId), address(tvAuction));
    }

    function testCreateAuctionCanBeDoneForTheSameItemWhenPreviousAuctionEnded()
        public
    {
        createAuction(SELLER);

        skip(1000);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        auctionParams.startTime = uint32(block.timestamp);
        giveApprovalAndCreateAuction(SELLER);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.status, true);
        assertEq(auction.seller, SELLER);
        assertEq(auction.startTime, auctionParams.startTime);
        assertEq(
            auction.endOfBiddingPeriod,
            auctionParams.startTime + auctionParams.bidPeriod
        );
        assertEq(
            auction.endOfRevealPeriod,
            auctionParams.startTime +
                auctionParams.bidPeriod +
                auctionParams.revealPeriod
        );
        assertEq(auction.highestBid, auctionParams.reservePrice);
        assertEq(auction.secondHighestBid, auctionParams.reservePrice);
        assertEq(auction.highestBidder, address(0));
        assertEq(auction.index, 2); // index will be 2 now.
        assertEq(auction.numUnrevealedBids, 0);
        assertEq(auction.highestBid, auctionParams.reservePrice);
        assertEq(auction.secondHighestBid, auctionParams.reservePrice);

        assertEq(erc721Mock.ownerOf(auctionParams.tokenId), address(tvAuction));
    }

    function testCreationAuctionCannotBeDoneForTheSameItemBeforeTheEndOfPreviousAuction()
        public
    {
        createAuction(SELLER);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__AUCTION_EXISTS.selector,
                auction.startTime,
                auction.endOfRevealPeriod
            )
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeDoneForTheSameItemWhenPreviousAuctionIsOngoing()
        public
    {
        createAuction(SELLER);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        skip(50);

        auctionParams.startTime = uint32(block.timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__AUCTION_EXISTS.selector,
                auction.startTime,
                auction.endOfRevealPeriod
            )
        );
        createAuction(SELLER);
    }

    function testCreateAcutionCannotBeDoneForTheSameItemWithoutEndingEvenIfTheRevealPeriodIsDone()
        public
    {
        createAuction(SELLER);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        skip(1000);

        auctionParams.startTime = uint32(block.timestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__AUCTION_EXISTS.selector,
                auction.startTime,
                auction.endOfRevealPeriod
            )
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeDoneWithZeroTokenContract() public {
        auctionParams.tokenContract = address(0);
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__TOKEN_ADDRESS_CANNOT_BE_ZERO.selector
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeDoneWithZeroErc20Address() public {
        auctionParams.erc20Token = address(0);
        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__ERC20_TOKEN_ADDRESS_CANNOT_BE_ZERO
                .selector
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeCreatedInThePast() public {
        skip(120);
        auctionParams.startTime = uint32(block.timestamp) - 100;
        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__CANNOT_CREATE_AUCTION_IN_THE_PAST
                .selector
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeCreatedWithZeroBidPeriod() public {
        auctionParams.bidPeriod = 0;
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__DEFINE_BID_REVEAL_PERIOD.selector
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeCreatedWithZeroRevealPeriod() public {
        auctionParams.revealPeriod = 0;
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__DEFINE_BID_REVEAL_PERIOD.selector
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeCreatedWithZeroReservePrice() public {
        auctionParams.reservePrice = 0;
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__RESERVED_PRICE_CANNOT_BE_ZERO.selector
        );
        createAuction(SELLER);
    }

    function testCreateAuctionCannotBeDoneIfTheTokenIsNotOwnedByTheSeller()
        public
    {
        erc721Mock.mint(address(this), 3);

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__AUCTION_TOKEN_IS_NOT_OWNED_BY_SELLER
                .selector
        );
        auctionParams.tokenId = 3;
        createAuction(SELLER);
    }

    function testCreateAcutionCannotBeDoneIfTheTokenApprovalIsNotGiven()
        public
    {
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__AUCTION_TOKEN_IS_NOT_APPROVED.selector
        );
        auctionParams.tokenId = 2;
        createAuction(SELLER);
    }

    function testCommitBidCannotBeDoneBeforeAuctionStartTime() public {
        auctionParams.startTime = uint32(block.timestamp) + 100;
        createAuction(SELLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__BID_PERIOD_NOT_STARTED.selector,
                auctionParams.startTime
            )
        );
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            getCommitment(0, 100, 1),
            100
        );
    }

    function testCommitBidCannotBeDoneForNonExistentAuction() public {
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__AUCTION_DOES_NOT_EXIST.selector
        );
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            getCommitment(0, 100, 1),
            100
        );
    }

    function testCommitBidCannotBeDoneAfterBidPeriodIsDone() public {
        createAuction(SELLER);

        skip(auctionParams.bidPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__BID_PERIOD_IS_OVER.selector,
                auctionParams.startTime + auctionParams.bidPeriod
            )
        );
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            getCommitment(0, 100, 1),
            100
        );
    }

    function testCommitBidCannotBeDoneWithZeroBidValue() public {
        createAuction(SELLER);

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__BID_COLLATERAL_CANNOT_BE_ZERO.selector
        );
        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            getCommitment(0, 0, 1),
            0
        );
    }

    function testCommitBidCommitmentCannotBeEmpty() public {
        createAuction(SELLER);

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__BID_COMMITMENT_CANNOT_BE_EMPTY.selector
        );
        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bytes20(0),
            100
        );
    }

    function testCommitBidCannotBeDoneWithoutErc20TokenApproval() public {
        createAuction(SELLER);

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__BID_NOT_ENOUGH_TOKEN_ALLOWANCE.selector
        );
        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            getCommitment(0, 100, 1),
            100
        );
    }

    function testCommitBidCannotBeDoneWithoutEnoughErc20TokenBalance(
        uint64 extraValue
    ) public {
        createAuction(SELLER);

        uint256 erc20Tokens = 1000 + uint96(extraValue) + 1;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);
        console2.log("balance", erc20Mock.balanceOf(BUYER1));

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__BID_NOT_ENOUGH_TOKEN_BALANCE.selector
        );

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            getCommitment(0, uint96(erc20Tokens), 1),
            erc20Tokens
        );
    }

    function testCommitBidSuccess() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 1000;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        bytes20 commitment = getCommitment(nonce, uint96(erc20Tokens), 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, commitment);
        assertEq(bidCollateral, erc20Tokens);
        assertEq(auction.numUnrevealedBids, 1);

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            1000 - erc20Tokens,
            "buyer1 erc20 balance is not correct"
        );
        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            erc20Tokens,
            "auction erc20 balance is not correct"
        );
    }

    function testCommitBidRewriteBid() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 200;

        giveERC20Approval(BUYER1, address(tvAuction), 100000);

        bytes32 nonce = bytes32("123");
        bytes20 commitment = getCommitment(nonce, uint96(erc20Tokens), 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            1000 - erc20Tokens,
            "buyer1 erc20 balance is not correct"
        );
        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            erc20Tokens,
            "auction erc20 balance is not correct"
        );

        uint256 erc20Tokens1 = 300;
        nonce = bytes32("456");
        commitment = getCommitment(nonce, uint96(erc20Tokens1), 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens1
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, commitment);
        assertEq(bidCollateral, erc20Tokens1 + erc20Tokens);
        assertEq(
            auction.numUnrevealedBids,
            1,
            "numUnrevealedBids is not correct"
        );

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            1000 - erc20Tokens - erc20Tokens1,
            "buyer1 erc20 balance is not correct"
        );

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            erc20Tokens1 + erc20Tokens,
            "auction erc20 balance is not correct"
        );
    }

    function testRevealBidCannotBeDoneOnNonExistentAuction() public {
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__AUCTION_DOES_NOT_EXIST.selector
        );
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            100,
            bytes32("123")
        );
    }

    function testRevealBidCannotbeDoneBeforeTheStartOfRevealPeriod() public {
        createAuction(SELLER);

        skip(auctionParams.bidPeriod - 2);

        assertEq(
            block.timestamp,
            auctionParams.startTime + auctionParams.bidPeriod - 2
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__REVEAL_PERIOD_NOT_STARTED.selector,
                auctionParams.startTime + auctionParams.bidPeriod
            )
        );
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            100,
            bytes32("123")
        );
    }

    function testRevealBidCannotBeDoneAfterTheEndOfRevealPeriod() public {
        createAuction(SELLER);

        skip(auctionParams.bidPeriod + auctionParams.revealPeriod);

        assertEq(
            block.timestamp,
            auctionParams.startTime +
                auctionParams.bidPeriod +
                auctionParams.revealPeriod
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__REVEAL_PERIOD_IS_OVER.selector,
                auctionParams.startTime +
                    auctionParams.bidPeriod +
                    auctionParams.revealPeriod
            )
        );
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            100,
            bytes32("123")
        );
    }

    function testRevealBidCannotBeDoneWithNonExistentBid() public {
        createAuction(SELLER);

        skip(auctionParams.bidPeriod);

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__REVEAL_BID_COMMITMENT_NOT_FOUND
                .selector
        );
        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            100,
            bytes32("123")
        );
    }

    function testRevealBidCannotBeDoneWithWrongNonceOrBidValue() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__REVEAL_BID_COMMITMENT_VERIFICATION_FAILED
                .selector
        );
        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            bytes32("456") // Incorrect Nonce
        );

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__REVEAL_BID_COMMITMENT_VERIFICATION_FAILED
                .selector
        );
        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue + 1, // Incorrect Bid Value
            nonce
        );
    }

    function testRevealBidCannotBeDoneTwice() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue, "bidCollateral is not correct");

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__REVEAL_BID_ALREADY_REVEALED.selector
        );
        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );
    }

    function testRevealBidWithHighestBid() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue, "bidCollateral is not correct");

        assertEq(auction.highestBid, bidValue, "highestBid is not correct");
        assertEq(
            auction.secondHighestBid,
            auctionParams.reservePrice,
            "secondHighestBid is not correct"
        );
        assertEq(auction.highestBidder, BUYER1, "highestBidder is not correct");
    }

    function testRevealBidWithSecondHighestBid() public {
        createAuction(SELLER);

        uint256 erc20Tokens1 = 500;
        uint256 erc20Tokens2 = 600;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens1);
        giveERC20Approval(BUYER2, address(tvAuction), erc20Tokens2);

        bytes32 nonce1 = bytes32("123");
        uint96 bidValue1 = uint96(erc20Tokens1);
        bytes20 commitment1 = getCommitment(nonce1, bidValue1, 1);

        bytes32 nonce2 = bytes32("456");
        uint96 bidValue2 = uint96(erc20Tokens2);
        bytes20 commitment2 = getCommitment(nonce2, bidValue2, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment1,
            erc20Tokens1
        );

        vm.prank(BUYER2);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment2,
            erc20Tokens2
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue1,
            nonce1
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 1);

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue1, "bidCollateral is not correct");

        assertEq(auction.highestBid, bidValue1, "highestBid is not correct");
        assertEq(
            auction.secondHighestBid,
            auctionParams.reservePrice,
            "secondHighestBid is not correct"
        );
        assertEq(auction.highestBidder, BUYER1, "highestBidder is not correct");

        vm.prank(BUYER2);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue2,
            nonce2
        );

        auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);

        (bidCommitment, bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER2
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue2, "bidCollateral is not correct");

        assertEq(auction.highestBid, bidValue2, "highestBid is not correct");
        assertEq(
            auction.secondHighestBid,
            bidValue1,
            "secondHighestBid is not correct"
        );
        assertEq(auction.highestBidder, BUYER2, "highestBidder is not correct");
    }

    function testRevealBidWithSecondHighestBid21() public {
        createAuction(SELLER);

        uint256 erc20Tokens1 = 600;
        uint256 erc20Tokens2 = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens1);
        giveERC20Approval(BUYER2, address(tvAuction), erc20Tokens2);

        bytes32 nonce1 = bytes32("123");
        uint96 bidValue1 = uint96(erc20Tokens1);
        bytes20 commitment1 = getCommitment(nonce1, bidValue1, 1);

        bytes32 nonce2 = bytes32("456");
        uint96 bidValue2 = uint96(erc20Tokens2);
        bytes20 commitment2 = getCommitment(nonce2, bidValue2, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment1,
            erc20Tokens1
        );

        vm.prank(BUYER2);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment2,
            erc20Tokens2
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue1,
            nonce1
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 1);

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue1, "bidCollateral is not correct");

        assertEq(auction.highestBid, bidValue1, "highestBid is not correct");
        assertEq(
            auction.secondHighestBid,
            auctionParams.reservePrice,
            "secondHighestBid is not correct"
        );
        assertEq(auction.highestBidder, BUYER1, "highestBidder is not correct");

        vm.prank(BUYER2);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue2,
            nonce2
        );

        auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);

        (bidCommitment, bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER2
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue2, "bidCollateral is not correct");

        assertEq(auction.highestBid, bidValue1, "highestBid is not correct");
        assertEq(
            auction.secondHighestBid,
            bidValue2,
            "secondHighestBid is not correct"
        );

        assertEq(auction.highestBidder, BUYER1, "highestBidder is not correct");
    }

    function testRevealBidWithHighestBidButLessCollateral() public {
        createAuction(SELLER);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(500);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        giveERC20Approval(BUYER1, address(tvAuction), bidValue);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            bidValue - 1
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCommitment, BID_REVEALED, "bidCommitment is not correct");
        assertEq(bidCollateral, bidValue - 1, "bidCollateral is not correct");

        assertEq(
            auction.highestBid,
            auctionParams.reservePrice,
            "highestBid is not correct"
        );
        assertEq(
            auction.secondHighestBid,
            auctionParams.reservePrice,
            "secondHighestBid is not correct"
        );

        assertEq(
            auction.highestBidder,
            address(0),
            "highestBidder is not correct"
        );
    }

    function testEndAuctionWithNonExistentAuction() public {
        vm.expectRevert(
            TokenizedVickeryAuction.TVA__AUCTION_DOES_NOT_EXIST.selector
        );
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );
    }

    function testEndAuctionCannotBeDoneOtherThanSeller() public {
        createAuction(SELLER);

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__END_AUCTION_ONLY_BY_SELLER.selector
        );
        vm.prank(BUYER1);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );
    }

    function testEndAuctionCannotBeDoneBeforeTheStartOfRevealPeriod() public {
        createAuction(SELLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction.TVA__REVEAL_PERIOD_NOT_STARTED.selector,
                auctionParams.startTime + auctionParams.bidPeriod
            )
        );
        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );
    }

    function testEndAuctionCannotBeDoneBeforeRevealPeriodIsOverWithUnRevealedBids()
        public
    {
        createAuction(SELLER);

        uint256 erc20Tokens = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 1);

        vm.prank(SELLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVickeryAuction
                    .TVA__AUCTION_HAS_UNREVEALED_BIDS_AND_IS_IN_REVEAL_PERIOD
                    .selector,
                auction.endOfRevealPeriod
            )
        );
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );
    }

    function testEndAuctionBeforeRevealPeriodWithNoUnRevealedBids() public {
        createAuction(SELLER);

        skip(auctionParams.bidPeriod);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        auction = getAuction();

        assertEq(auction.status, false);
        assertEq(auction.seller, SELLER);
        assertEq(auction.endOfRevealPeriod, block.timestamp);
    }

    function testEndAuctionAfterRevealPeriodWithUnRevealedBids() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);
        skip(auctionParams.revealPeriod);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.status, false);
        assertEq(auction.seller, SELLER);
        assertEq(auction.endOfRevealPeriod, block.timestamp);
    }

    function testEndAuctionWithNoBids() public {
        createAuction(SELLER);

        skip(auctionParams.bidPeriod);
        skip(auctionParams.revealPeriod);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.status, false);
        assertEq(auction.seller, SELLER);
        assertEq(auction.endOfRevealPeriod, block.timestamp);

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            0,
            "auction erc20 balance is not correct"
        );

        assertEq(erc721Mock.ownerOf(auctionParams.tokenId), SELLER);
    }

    function testEndAuctionWithNoHighestBid() public {
        createAuction(SELLER);

        uint256 erc20Tokens = auctionParams.reservePrice - 1;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);
        assertEq(auction.highestBid, auctionParams.reservePrice);
        assertEq(auction.highestBidder, address(0));

        skip(auctionParams.revealPeriod);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        auction = getAuction();

        assertEq(auction.status, false);
        assertEq(auction.seller, SELLER);
        assertEq(auction.endOfRevealPeriod, block.timestamp);

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            erc20Tokens,
            "auction erc20 balance is not correct"
        );

        assertEq(erc721Mock.ownerOf(auctionParams.tokenId), SELLER);
    }

    function testEndAuctionWithHighestBid() public {
        createAuction(SELLER);

        uint256 erc20Tokens = auctionParams.reservePrice + 1;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);
        assertEq(auction.highestBid, bidValue);
        assertEq(auction.highestBidder, BUYER1);

        uint256 sellerErc20Balance = erc20Mock.balanceOf(SELLER);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        auction = getAuction();

        assertEq(auction.status, false);

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            0,
            "auction erc20 balance is not correct"
        );

        assertEq(erc721Mock.ownerOf(auctionParams.tokenId), BUYER1);

        assertEq(
            erc20Mock.balanceOf(SELLER),
            sellerErc20Balance + erc20Tokens,
            "seller erc20 balance is not correct"
        );
    }

    function testEndAuctionWithHighestBidExcessCollateral() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 400;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens - 200);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        (bytes20 bidCommitment, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            1,
            BUYER1
        );

        assertEq(bidCommitment, commitment, "bidCommitment is not correct");
        assertEq(bidCollateral, erc20Tokens, "bidCollateral is not correct");

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);
        assertEq(auction.highestBid, bidValue, "highestBid is not correct");
        assertEq(auction.highestBidder, BUYER1, "highestBidder is not correct");

        uint256 sellerErc20Balance = erc20Mock.balanceOf(SELLER);
        uint256 buyer1Erc20Balance = erc20Mock.balanceOf(BUYER1);

        vm.prank(SELLER);
        tvAuction.endAuction(
            auctionParams.tokenContract,
            auctionParams.tokenId
        );

        auction = getAuction();

        assertEq(auction.status, false);

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            0,
            "auction erc20 balance is not correct"
        );

        assertEq(erc721Mock.ownerOf(auctionParams.tokenId), BUYER1);

        assertEq(
            erc20Mock.balanceOf(SELLER),
            sellerErc20Balance + bidValue,
            "seller erc20 balance is not correct"
        );

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            buyer1Erc20Balance + (erc20Tokens - bidValue),
            "buyer1 erc20 balance is not correct"
        );
    }

    function testWithdrawCollateralCannotBeDoneWithoutCommitingBid() public {
        createAuction(SELLER);

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__WITHDRAW_COLLATERAL_BID_NOT_FOUND
                .selector
        );
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );
    }

    function testWithdrawCollateralCannotBeDoneWithoutRevealingBid() public {
        createAuction(SELLER);

        uint256 erc20Tokens = auctionParams.reservePrice;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );
        TokenizedVickeryAuction.Auction memory auction = getAuction();

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__WITHDRAW_COLLATERAL_BID_NOT_REVEALED
                .selector
        );
        vm.prank(BUYER1);
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );
    }

    function testWithdrawCollateralCannotBeDoneWithHighestBidder() public {
        createAuction(SELLER);

        uint256 erc20Tokens = 500;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );
        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );
        TokenizedVickeryAuction.Auction memory auction = getAuction();

        vm.expectRevert(
            TokenizedVickeryAuction
                .TVA__WITHDRAW_COLLATERAL_BID_IS_HIGHEST_BIDDER
                .selector
        );
        vm.prank(BUYER1);
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );
    }

    function testWithdrawCollateralSuccess() public {
        createAuction(SELLER);

        uint256 erc20Tokens = auctionParams.reservePrice - 1;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment1 = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment1,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        uint256 buyer1Erc20Balance = erc20Mock.balanceOf(BUYER1);
        uint256 auctionErc20Balance = erc20Mock.balanceOf(address(tvAuction));

        vm.prank(BUYER1);
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            buyer1Erc20Balance + erc20Tokens,
            "buyer1 erc20 balance is not correct"
        );

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            auctionErc20Balance - erc20Tokens,
            "auction erc20 balance is not correct"
        );

        (, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCollateral, 0, "bidCollateral is not correct");
    }

    function testWithdrawCollateralWithSecondHighestBidder() public {
        createAuction(SELLER);

        uint256 erc20Tokens1 = 500;
        uint256 erc20Tokens2 = 600;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens1);
        giveERC20Approval(BUYER2, address(tvAuction), erc20Tokens2);

        bytes32 nonce1 = bytes32("123");
        uint96 bidValue1 = uint96(erc20Tokens1);
        bytes20 commitment1 = getCommitment(nonce1, bidValue1, 1);

        bytes32 nonce2 = bytes32("456");
        uint96 bidValue2 = uint96(erc20Tokens2);
        bytes20 commitment2 = getCommitment(nonce2, bidValue2, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment1,
            erc20Tokens1
        );

        vm.prank(BUYER2);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment2,
            erc20Tokens2
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue1,
            nonce1
        );

        vm.prank(BUYER2);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue2,
            nonce2
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        assertEq(auction.numUnrevealedBids, 0);
        assertEq(auction.highestBid, bidValue2, "highestBid is not correct");
        assertEq(
            auction.secondHighestBid,
            bidValue1,
            "secondHighestBid is not correct"
        );
        assertEq(auction.highestBidder, BUYER2, "highestBidder is not correct");

        uint256 buyer1Erc20Balance = erc20Mock.balanceOf(BUYER1);
        uint256 auctionErc20Balance = erc20Mock.balanceOf(address(tvAuction));

        vm.prank(BUYER1);
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            buyer1Erc20Balance + erc20Tokens1,
            "buyer1 erc20 balance is not correct"
        );

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            auctionErc20Balance - erc20Tokens1,
            "auction erc20 balance is not correct"
        );

        (, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCollateral, 0, "bidCollateral is not correct");
    }

    function testWithdrawCollateralCannotBeDoneTwice() public {
        createAuction(SELLER);

        uint256 erc20Tokens = auctionParams.reservePrice - 1;

        giveERC20Approval(BUYER1, address(tvAuction), erc20Tokens);

        bytes32 nonce = bytes32("123");
        uint96 bidValue = uint96(erc20Tokens);
        bytes20 commitment = getCommitment(nonce, bidValue, 1);

        vm.prank(BUYER1);
        tvAuction.commitBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            commitment,
            erc20Tokens
        );

        skip(auctionParams.bidPeriod);

        vm.prank(BUYER1);
        tvAuction.revealBid(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            bidValue,
            nonce
        );

        TokenizedVickeryAuction.Auction memory auction = getAuction();

        uint256 buyer1Erc20Balance = erc20Mock.balanceOf(BUYER1);
        uint256 auctionErc20Balance = erc20Mock.balanceOf(address(tvAuction));

        vm.prank(BUYER1);
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );

        assertEq(
            erc20Mock.balanceOf(BUYER1),
            buyer1Erc20Balance + erc20Tokens,
            "buyer1 erc20 balance is not correct"
        );

        assertEq(
            erc20Mock.balanceOf(address(tvAuction)),
            auctionErc20Balance - erc20Tokens,
            "auction erc20 balance is not correct"
        );

        (, uint96 bidCollateral) = tvAuction.bids(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index,
            BUYER1
        );

        assertEq(bidCollateral, 0, "bidCollateral is not correct");

        vm.expectRevert(
            TokenizedVickeryAuction.TVA__WITHDRAW_COLLATERAL_IS_ZERO.selector
        );
        vm.prank(BUYER1);
        tvAuction.withdrawCollateral(
            auctionParams.tokenContract,
            auctionParams.tokenId,
            auction.index
        );
    }
}
