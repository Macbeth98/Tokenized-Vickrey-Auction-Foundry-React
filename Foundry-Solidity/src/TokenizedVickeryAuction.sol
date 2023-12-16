// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title Tokenized Vickery Auction: An on-chain, over-collateralization, sealed-bid, second-price auction.
 * @author suhabe, Macbeth98 
 * @notice The TokenizedVickeryAuction implements the auction mechanism with the following two extensions:
            - Bids should be accepted in ERC20 tokens rather than ether.
            - Items should be ERC721 tokens rather than just an off-chain asset.

 */
contract TokenizedVickeryAuction {
    error TVA__TOKEN_ADDRESS_CANNOT_BE_ZERO();
    error TVA__ERC20_TOKEN_ADDRESS_CANNOT_BE_ZERO();
    error TVA__CANNOT_CREATE_AUCTION_IN_THE_PAST();
    error TVA__DEFINE_BID_REVEAL_PERIOD();
    error TVA__RESERVED_PRICE_CANNOT_BE_ZERO();
    error TVA__AUCTION_EXISTS(uint32 startTime, uint32 endTime);
    error TVA__AUCTION_EXISTS_NOT_ENDED();
    error TVA__AUCTION_DOES_NOT_EXIST();
    error TVA__AUCTION_TOKEN_IS_NOT_OWNED_BY_SELLER();
    error TVA__AUCTION_TOKEN_IS_NOT_APPROVED();

    error TVA__BID_PERIOD_NOT_STARTED(uint32 startTime);
    error TVA__BID_PERIOD_IS_OVER(uint32 endTime);
    error TVA__BID_COLLATERAL_CANNOT_BE_ZERO();
    error TVA__BID_COMMITMENT_CANNOT_BE_EMPTY();
    error TVA__BID_NOT_ENOUGH_TOKEN_ALLOWANCE();
    error TVA__BID_NOT_ENOUGH_TOKEN_BALANCE();

    error TVA__REVEAL_PERIOD_NOT_STARTED(uint32 startTime);
    error TVA__REVEAL_PERIOD_IS_OVER(uint32 endTime);
    error TVA__REVEAL_BID_COMMITMENT_VERIFICATION_FAILED();
    error TVA__REVEAL_BID_COMMITMENT_NOT_FOUND();
    error TVA__REVEAL_BID_ALREADY_REVEALED();

    error TVA__AUCTION_HAS_UNREVEALED_BIDS_AND_IS_IN_REVEAL_PERIOD(
        uint32 endTime
    );
    error TVA__END_AUCTION_ONLY_BY_SELLER();

    error TVA__WITHDRAW_COLLATERAL_BID_NOT_FOUND();
    error TVA__WITHDRAW_COLLATERAL_BID_NOT_REVEALED();
    error TVA__WITHDRAW_COLLATERAL_BID_IS_HIGHEST_BIDDER();
    error TVA__WITHDRAW_COLLATERAL_IS_ZERO();

    /// @dev Representation of an auction in storage. Occupies three slots.
    /// @param status The status of the auction, where: true = active, false = ended.
    /// @param seller The address selling the auctioned asset.
    /// @param startTime The unix timestamp at which bidding can start.
    /// @param endOfBiddingPeriod The unix timestamp after which bids can no
    ///        longer be placed.
    /// @param endOfRevealPeriod The unix timestamp after which commitments can
    ///        no longer be opened.
    /// @param numUnrevealedBids The number of bid commitments that have not
    ///        yet been opened.
    /// @param highestBid The value of the highest bid revealed so far, or
    ///        the reserve price if no bids have exceeded it.
    /// @param secondHighestBid The value of the second-highest bid revealed
    ///        so far, or the reserve price if no two bids have exceeded it.
    /// @param highestBidder The bidder that placed the highest bid.
    /// @param index Auctions selling the same asset (i.e. tokenContract-tokenId
    ///        pair) share the same storage. This value is incremented for
    ///        each new auction of a particular asset.
    struct Auction {
        bool status;
        address seller;
        uint32 startTime;
        uint32 endOfBiddingPeriod;
        uint32 endOfRevealPeriod;
        // =====================
        uint64 numUnrevealedBids;
        uint96 highestBid;
        uint96 secondHighestBid;
        // =====================
        address highestBidder;
        uint64 index;
        address erc20Token;
    }

    /// @param commitment The hash commitment of a bid value.
    /// @param collateral The amount of collateral backing the bid.
    struct Bid {
        bytes20 commitment;
        uint96 collateral;
    }

    bytes20 private constant BID_REVEALED = bytes20("Bid Revealed");

    /// @notice A mapping storing auction parameters and state, indexed by
    ///         the ERC721 contract address and token ID of the asset being
    ///         auctioned.
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /// @notice A mapping storing bid commitments and records of collateral,
    ///         indexed by: ERC721 contract address, token ID, auction index,
    ///         and bidder address. If the commitment is `bytes20(0)`, either
    ///         no commitment was made or the commitment was opened.
    mapping(address => mapping(uint256 => mapping(uint64 => mapping(address => Bid)))) // ERC721 token contract // ERC721 token ID // Auction index // Bidder
        public bids;

    /** EVENTS */
    event AuctionCreated(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint32 startTime,
        uint32 endTime,
        uint96 reservePrice,
        uint64 auctionIndex,
        address erc20Token
    );

    event BidCommitted(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed bidder,
        uint64 auctionIndex,
        uint96 collateral
    );

    event BidRevealed(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed bidder,
        uint64 auctionIndex,
        uint96 bidValue
    );

    event AuctionEnded(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed winner,
        uint96 winningBid
    );

    event CollateralWithdrawn(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed bidder,
        uint64 auctionIndex,
        uint96 collateral
    );

    /// @notice Creates an auction for the given ERC721 asset with the given
    ///         auction parameters.
    /// @param tokenContract The address of the ERC721 contract for the asset
    ///        being auctioned.
    /// @param tokenId The ERC721 token ID of the asset being auctioned.
    /// @param startTime The unix timestamp at which bidding can start.
    /// @param bidPeriod The duration of the bidding period, in seconds.
    /// @param revealPeriod The duration of the commitment reveal period,
    ///        in seconds.
    /// @param reservePrice The minimum price that the asset will be sold for.
    ///        If no bids exceed this price, the asset is returned to `seller`.
    function createAuction(
        address tokenContract,
        uint256 tokenId,
        address erc20Token,
        uint32 startTime,
        uint32 bidPeriod,
        uint32 revealPeriod,
        uint96 reservePrice
    ) external virtual {
        _createAuction(
            tokenContract,
            tokenId,
            erc20Token,
            startTime,
            bidPeriod,
            revealPeriod,
            reservePrice
        );
    }

    function _createAuction(
        address tokenContract,
        uint256 tokenId,
        address erc20Token,
        uint32 startTime,
        uint32 bidPeriod,
        uint32 revealPeriod,
        uint96 reservePrice
    ) internal {
        if (tokenContract == address(0)) {
            revert TVA__TOKEN_ADDRESS_CANNOT_BE_ZERO();
        }

        if (erc20Token == address(0)) {
            revert TVA__ERC20_TOKEN_ADDRESS_CANNOT_BE_ZERO();
        }

        if (startTime < block.timestamp) {
            revert TVA__CANNOT_CREATE_AUCTION_IN_THE_PAST();
        }

        if (bidPeriod == 0 || revealPeriod == 0) {
            revert TVA__DEFINE_BID_REVEAL_PERIOD();
        }

        if (reservePrice == 0) {
            revert TVA__RESERVED_PRICE_CANNOT_BE_ZERO();
        }

        Auction storage auction = auctions[tokenContract][tokenId];

        if (auction.status) {
            revert TVA__AUCTION_EXISTS(
                auction.startTime,
                auction.endOfRevealPeriod
            );
        }

        IERC721 erc721Token = IERC721(tokenContract);

        if (erc721Token.ownerOf(tokenId) != msg.sender) {
            revert TVA__AUCTION_TOKEN_IS_NOT_OWNED_BY_SELLER();
        }

        if (erc721Token.getApproved(tokenId) != address(this)) {
            revert TVA__AUCTION_TOKEN_IS_NOT_APPROVED();
        }

        erc721Token.transferFrom(msg.sender, address(this), tokenId);

        uint64 index = auction.index + 1;

        if (auction.startTime > 0) {
            // sharing the same storage
            auction.status = true;
            auction.startTime = startTime;
            auction.endOfBiddingPeriod = startTime + bidPeriod;
            auction.endOfRevealPeriod = startTime + bidPeriod + revealPeriod;
            auction.numUnrevealedBids = 0;
            auction.highestBid = reservePrice;
            auction.secondHighestBid = reservePrice;
            auction.highestBidder = address(0);
            auction.index = index;
            auction.erc20Token = erc20Token;
        } else {
            // new token -> new storage
            Auction memory newAuction = Auction({
                status: true,
                seller: msg.sender,
                startTime: startTime,
                endOfBiddingPeriod: startTime + bidPeriod,
                endOfRevealPeriod: startTime + bidPeriod + revealPeriod,
                numUnrevealedBids: 0,
                highestBid: reservePrice,
                secondHighestBid: reservePrice,
                highestBidder: address(0),
                index: index,
                erc20Token: erc20Token
            });

            auctions[tokenContract][tokenId] = newAuction;
        }

        emit AuctionCreated(
            tokenContract,
            tokenId,
            msg.sender,
            startTime,
            startTime + bidPeriod,
            reservePrice,
            index,
            erc20Token
        );
    }

    /// @notice Commits to a bid on an item being auctioned. If a bid was
    ///         previously committed to, overwrites the previous commitment.
    ///         Value attached to this call is used as collateral for the bid.
    /// @param tokenContract The address of the ERC721 contract for the asset
    ///        being auctioned.
    /// @param tokenId The ERC721 token ID of the asset being auctioned.
    /// @param commitment The commitment to the bid, computed as
    ///        `bytes20(keccak256(abi.encode(nonce, bidValue, tokenContract, tokenId, auctionIndex)))`.
    /// @param erc20Tokens The amount of ERC20 tokens to be used as collateral
    function commitBid(
        address tokenContract,
        uint256 tokenId,
        bytes20 commitment,
        uint256 erc20Tokens
    ) external {
        Auction storage auction = auctions[tokenContract][tokenId];

        if (!auction.status) {
            revert TVA__AUCTION_DOES_NOT_EXIST();
        }

        if (block.timestamp < auction.startTime) {
            revert TVA__BID_PERIOD_NOT_STARTED(auction.startTime);
        }

        if (block.timestamp >= auction.endOfBiddingPeriod) {
            revert TVA__BID_PERIOD_IS_OVER(auction.endOfBiddingPeriod);
        }

        if (erc20Tokens == 0) {
            revert TVA__BID_COLLATERAL_CANNOT_BE_ZERO();
        }

        if (commitment == bytes20(0)) {
            revert TVA__BID_COMMITMENT_CANNOT_BE_EMPTY();
        }

        IERC20 erc20Token = IERC20(auction.erc20Token);

        if (erc20Token.allowance(msg.sender, address(this)) < erc20Tokens) {
            revert TVA__BID_NOT_ENOUGH_TOKEN_ALLOWANCE();
        }

        if (erc20Token.balanceOf(msg.sender) < erc20Tokens) {
            revert TVA__BID_NOT_ENOUGH_TOKEN_BALANCE();
        }

        erc20Token.transferFrom(msg.sender, address(this), erc20Tokens);

        uint96 collateral = uint96(erc20Tokens);

        uint64 auctionIndex = auction.index;

        Bid memory bid = bids[tokenContract][tokenId][auctionIndex][msg.sender];

        if (bid.commitment != bytes20(0)) {
            auction.numUnrevealedBids -= 1;
            collateral += bid.collateral;
        }

        bids[tokenContract][tokenId][auctionIndex][msg.sender] = Bid({
            commitment: commitment,
            collateral: collateral
        });

        auction.numUnrevealedBids += 1;

        emit BidCommitted(
            tokenContract,
            tokenId,
            msg.sender,
            auctionIndex,
            collateral
        );
    }

    /// @notice Reveals the value of a bid that was previously committed to.
    /// @param tokenContract The address of the ERC721 contract for the asset
    ///        being auctioned.
    /// @param tokenId The ERC721 token ID of the asset being auctioned.
    /// @param bidValue The value of the bid.
    /// @param nonce The random input used to obfuscate the commitment.
    function revealBid(
        address tokenContract,
        uint256 tokenId,
        uint96 bidValue,
        bytes32 nonce
    ) external {
        Auction storage auction = auctions[tokenContract][tokenId];

        if (!auction.status) {
            revert TVA__AUCTION_DOES_NOT_EXIST();
        }

        if (block.timestamp < auction.endOfBiddingPeriod) {
            revert TVA__REVEAL_PERIOD_NOT_STARTED(auction.endOfBiddingPeriod);
        }

        if (block.timestamp >= auction.endOfRevealPeriod) {
            revert TVA__REVEAL_PERIOD_IS_OVER(auction.endOfRevealPeriod);
        }

        uint64 auctionIndex = auction.index;

        Bid storage bid = bids[tokenContract][tokenId][auctionIndex][
            msg.sender
        ];

        if (bid.commitment == bytes20(0)) {
            revert TVA__REVEAL_BID_COMMITMENT_NOT_FOUND();
        }

        if (bid.commitment == BID_REVEALED) {
            revert TVA__REVEAL_BID_ALREADY_REVEALED();
        }

        bytes20 commitment = bytes20(
            keccak256(
                abi.encode(
                    nonce,
                    bidValue,
                    tokenContract,
                    tokenId,
                    auctionIndex
                )
            )
        );

        if (commitment != bid.commitment) {
            revert TVA__REVEAL_BID_COMMITMENT_VERIFICATION_FAILED();
        }

        uint96 highestBid = auction.highestBid;

        if (bid.collateral >= bidValue) {
            if (bidValue > highestBid) {
                auction.secondHighestBid = highestBid;
                auction.highestBid = bidValue;
                auction.highestBidder = msg.sender;
            } else if (bidValue > auction.secondHighestBid) {
                auction.secondHighestBid = bidValue;
            }
        }

        bid.commitment = BID_REVEALED;

        auction.numUnrevealedBids -= 1;

        emit BidRevealed(
            tokenContract,
            tokenId,
            msg.sender,
            auctionIndex,
            bidValue
        );
    }

    /// @notice Ends an active auction. Can only end an auction if the bid reveal
    ///         phase is over, or if all bids have been revealed. Disburses the auction
    ///         proceeds to the seller. Transfers the auctioned asset to the winning
    ///         bidder and returns any excess collateral. If no bidder exceeded the
    ///         auction's reserve price, returns the asset to the seller.
    /// @param tokenContract The address of the ERC721 contract for the asset auctioned.
    /// @param tokenId The ERC721 token ID of the asset auctioned.
    function endAuction(address tokenContract, uint256 tokenId) external {
        Auction storage auction = auctions[tokenContract][tokenId];

        if (auction.status == false) {
            revert TVA__AUCTION_DOES_NOT_EXIST();
        }

        if (auction.seller != msg.sender) {
            revert TVA__END_AUCTION_ONLY_BY_SELLER();
        }

        if (block.timestamp < auction.endOfBiddingPeriod) {
            revert TVA__REVEAL_PERIOD_NOT_STARTED(auction.endOfBiddingPeriod);
        }

        if (block.timestamp < auction.endOfRevealPeriod) {
            if (auction.numUnrevealedBids > 0) {
                revert TVA__AUCTION_HAS_UNREVEALED_BIDS_AND_IS_IN_REVEAL_PERIOD(
                    auction.endOfRevealPeriod
                );
            }

            auction.endOfRevealPeriod = uint32(block.timestamp);
        }

        address highestBidder = auction.highestBidder;
        address seller = auction.seller;
        uint96 highestBid = auction.highestBid;
        uint64 auctionIndex = auction.index;

        IERC721 erc721Token = IERC721(tokenContract);

        auction.status = false; // set the auction status to end.

        if (highestBidder == address(0)) {
            erc721Token.transferFrom(address(this), seller, tokenId); // transfer back to seller
            emit AuctionEnded(
                tokenContract,
                tokenId,
                highestBidder,
                highestBid
            );
            return;
        }

        Bid storage bid = bids[tokenContract][tokenId][auctionIndex][
            highestBidder
        ];

        uint96 collateral = bid.collateral;

        uint96 excessCollateral = 0;

        if (collateral > highestBid) {
            excessCollateral = collateral - highestBid;
        }

        bid.collateral = 0;

        // transfer the token/asset to the highest bidder
        erc721Token.transferFrom(address(this), highestBidder, tokenId);

        // transfer the collateral to the seller
        IERC20 erc20Token = IERC20(auction.erc20Token);
        erc20Token.transfer(seller, highestBid);

        if (excessCollateral > 0) {
            erc20Token.transfer(highestBidder, excessCollateral);
        }

        emit AuctionEnded(tokenContract, tokenId, highestBidder, highestBid);
    }

    /// @notice Withdraws collateral. Bidder must have opened their bid commitment
    ///         and cannot be in the running to win the auction.
    /// @param tokenContract The address of the ERC721 contract for the asset
    ///        that was auctioned.
    /// @param tokenId The ERC721 token ID of the asset that was auctioned.
    /// @param auctionIndex The index of the auction that was being bid on.
    function withdrawCollateral(
        address tokenContract,
        uint256 tokenId,
        uint64 auctionIndex
    ) external {
        Auction storage auction = auctions[tokenContract][tokenId];

        if (auction.highestBidder == msg.sender) {
            revert TVA__WITHDRAW_COLLATERAL_BID_IS_HIGHEST_BIDDER();
        }

        Bid memory bid = bids[tokenContract][tokenId][auctionIndex][msg.sender];

        if (bid.commitment == bytes20(0)) {
            revert TVA__WITHDRAW_COLLATERAL_BID_NOT_FOUND();
        }

        if (bid.commitment != BID_REVEALED) {
            revert TVA__WITHDRAW_COLLATERAL_BID_NOT_REVEALED();
        }

        if (bid.collateral == 0) {
            revert TVA__WITHDRAW_COLLATERAL_IS_ZERO();
        }

        bids[tokenContract][tokenId][auctionIndex][msg.sender].collateral = 0;

        IERC20 erc20Token = IERC20(auction.erc20Token);

        erc20Token.transfer(msg.sender, bid.collateral);

        emit CollateralWithdrawn(
            tokenContract,
            tokenId,
            msg.sender,
            auctionIndex,
            bid.collateral
        );
    }

    /// @notice Gets the parameters and state of an auction in storage.
    /// @param tokenContract The address of the ERC721 contract for the asset auctioned.
    /// @param tokenId The ERC721 token ID of the asset auctioned.
    function getAuction(
        address tokenContract,
        uint256 tokenId
    ) external view returns (Auction memory auction) {
        auction = auctions[tokenContract][tokenId];
    }
}
