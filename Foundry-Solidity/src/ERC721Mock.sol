// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    constructor() ERC721("ERC721Mock", "E721M") {}

    function mint(address account, uint256 tokenId) external {
        _mint(account, tokenId);
    }
}
