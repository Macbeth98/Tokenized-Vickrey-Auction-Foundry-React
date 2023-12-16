-include .env

.PHONY: help deployERC20 test build

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage: make [target]"
	@echo "make deployERC20 [ARGS=...]"
	@echo "ARGS Example: rpc-url https://rpc.testnet.com private-key 0x1234567890abcdef --broadcast --verify --etherscan-api-key 1234567890abcdef -vvvv"
	@echo "ARGS Example to deploy to network sepolia: --network sepolia"

NETWORK_ARGS := --rpc-url ${rpc-url} --private-key ${private-key} --broadcast --verify --etherscan-api-key ${etherscan-api-key} -vvvv
NETWORK := anvil

# Checking if 'ARGS' contains '--network sepolia'
ifneq (,$(findstring --network sepolia,$(ARGS)))
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
	NETWORK := sepolia
endif

deployERC20:
	@echo "Deploying ERC20Tokens to $(NETWORK) network"
	@forge script script/DeployErc20.s.sol:DeployErc20 $(NETWORK_ARGS)

deployERC721:
	@echo "Deploying ERC721Tokens to $(NETWORK) network"
	@forge script script/DeployErc721.s.sol:DeployErc721 $(NETWORK_ARGS)

deployAuction:
	@echo "Deploying Auction to $(NETWORK) network"
	@forge script script/DeployAuction.s.sol:DeployAuction $(NETWORK_ARGS)


deployProxyAdmin:
	@echo "Deploying ProxyAdmin to $(NETWORK) network"
	@forge script script/DeployProxyAdmin.s.sol:DeployProxyAdmin $(NETWORK_ARGS)

deployProxy:
	@echo "Deploying Proxy to $(NETWORK) network"
	@forge script script/DeployProxy.s.sol:DeployProxy $(NETWORK_ARGS)

test:
	forge test

build:
	forge build
