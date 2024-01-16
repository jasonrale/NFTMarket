// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyERC721 is ERC721URIStorage {
    uint256 private counter;
    uint256 constant private TOTAL_SUPPLY = 10000;

    error MintOut(uint256 totalSupply);

    constructor() ERC721("Jason", "JASON") {}

    function mint(address account, string memory tokenURI) public returns (uint256) {
        ++counter;

        if (counter > TOTAL_SUPPLY) {
            revert MintOut(TOTAL_SUPPLY);
        }
        
        uint256 newItemId = counter;
        _mint(account, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}