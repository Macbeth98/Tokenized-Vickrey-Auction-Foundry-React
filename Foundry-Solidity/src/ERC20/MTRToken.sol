// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MTRToken is ERC20 {
    constructor() ERC20("MTRToken", "MTR") {
        _mint(msg.sender, 1000);
    }

    function mint(address account, uint256 amount) external {
        if (amount > 1000) {
            amount = 1000;
        }
        _mint(account, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
