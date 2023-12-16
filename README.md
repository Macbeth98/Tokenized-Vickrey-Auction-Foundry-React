## Auction in Solidity using Foundry Framework.

**This repo contains the implementation of a Auction contract, where each item being auctioned is an `NFT Token` and the collateral is `ERC20 Token` determined by the seller of the `NFT`. The Auction also has an Openzeppelin implementation of the Transaparent Upgradeability Pattern.**

# Contracts:

- **TokenizedVickeryAuction**: The main base Auction Contract, where sellers can create an Auction for the given `NFT Token` and a given `ERC20 Token` accepeted as Collateral.
- **TokenizedVickeryAuctionV2**: The version 2 of `TokenizedVickeryAuction` which has an additional functionality of blacklisting a Seller.
- **ERC721Mock**: A Mock implementation of ERC721 inheriting Openzeppelin ERC721 for testing prupose.
- **ERC20Mock**: A Mock implemenatation of ERC20 taken from Openzeppelin for testing purpose.

# Testing:

- All the contracts are throughly tested with **100% Code coverage**. Check the coverage folder for a graphical overview of the coverage generated with `forge coverage` and `lcov & genhtml`.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ make deploy ARGS="--network sepolia"
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
