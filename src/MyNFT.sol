// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract MyNFT is ERC721URIStorage, EIP712, Nonces {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("PermitList(address nft,address owner,address operator,bool approved,uint256 price,address currency,uint256 nonce)");
        
    uint256 private counter;
    uint256 private constant TOTAL_SUPPLY = 10000;

    error MintOut(uint256 totalSupply);
    error InvalidSigner(address signer, address owner);

    constructor() ERC721("Jason", "JASON") EIP712("MyNFT", "1"){}

    function mint(
        address account,
        string memory tokenURI
    ) public returns (uint256) {
        ++counter;

        if (counter > TOTAL_SUPPLY) {
            revert MintOut(TOTAL_SUPPLY);
        }

        uint256 newItemId = counter;
        _mint(account, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    /**
     * IERC721Permit
     */
    function permitList(
        address owner,
        address operator,
        bool approved,
        uint256 price,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, address(this), owner, operator, approved, price, currency, _useNonce(owner)));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert InvalidSigner(signer, owner);
        }

        _setApprovalForAll(owner, operator, approved);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return super.nonces(owner);
    }
}