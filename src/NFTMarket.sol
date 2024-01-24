// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

interface ERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract NFTMarket is EIP712, Nonces {
    using SafeERC20 for IERC20;

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address nft, uint256 tokenId, uint256 nonce)");
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    uint8 public FOR_SALE = 0;
    uint8 public SOLD = 1;
    uint8 public CANCELED = 2;

    address private _treasury;
    address private _owner;
    uint256 public defaultFeeRate;

    struct Item {
        uint256 tokenId;
        address nft;
        address currency;
        address seller;
        address buyer;
        uint8 status; //2 = sale canceled, 1 = sold, 0 = for sale
        uint256 price;
    }

    mapping(address nft => mapping(uint256 tokenId => Item)) public saleList;

    event ItemListed(
        address indexed nft,
        uint256 tokenId,
        uint256 indexed price,
        address currency,
        address indexed seller,
        uint8 status
    );
    event ItemSold(
        address indexed nft,
        uint256 tokenId,
        address indexed buyer,
        uint8 status
    );
    event ItemCanceled(address indexed nft, uint256 tokenId, uint8 status);

    constructor(uint256 feeRate, address treasury) EIP712("NFTMarket", "1") {
        defaultFeeRate = feeRate;
        _treasury = treasury;
        _owner = msg.sender;
    }

    function querySaleList(
        address nft,
        uint256 tokenId
    ) public view returns (Item memory) {
        return saleList[nft][tokenId];
    }

    function nonces(
        address owner
    ) public view virtual override returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * 生成消息哈希
     */
    function getHash(
        address nft,
        uint256 tokenId,
        address wlUser
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, nft, tokenId, nonces(wlUser))
        );
        return _hashTypedDataV4(structHash);
    }

    function listNFT(
        address nft,
        uint256 tokenId,
        uint256 price,
        address currency
    ) external {
        _ownerCheck(nft, tokenId);
        address seller = msg.sender;
        saleList[nft][tokenId] = Item(
            tokenId,
            nft,
            currency,
            seller,
            address(0),
            FOR_SALE,
            price
        );

        emit ItemListed(nft, tokenId, price, currency, msg.sender, FOR_SALE);
    }

    function cancelList(address nft, uint256 tokenId) external {
        _ownerCheck(nft, tokenId);
        Item memory item = saleList[nft][tokenId];
        item.status = CANCELED;

        saleList[nft][tokenId] = item;

        emit ItemCanceled(nft, tokenId, CANCELED);
    }

    function buyNFT(address nft, uint256 tokenId) public {
        Item memory item = saleList[nft][tokenId];
        address buyer = msg.sender;

        _buyCheck(item, buyer);
        _buy(tokenId, item, buyer);
        emit ItemSold(nft, tokenId, buyer, SOLD);
    }

    /**
     * 白名单购买
     */
    function buyNFTForWL(
        address nft,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(permit(nft, tokenId, v, r, s), "No Permission");
        Item memory item = saleList[nft][tokenId];
        address buyer = msg.sender;

        _buyCheck(item, buyer);
        _buy(tokenId, item, buyer);
        emit ItemSold(nft, tokenId, buyer, SOLD);
    }

    function tokenRecieved(
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bool) {
        Item memory param = abi.decode(data, (Item));
        address nft = param.nft;
        uint256 tokenId = param.tokenId;
        Item memory item = saleList[nft][tokenId];
        require(item.price == value, "Token amount error");

        _buyCheck(item, from);
        _buy(tokenId, item, from);

        emit ItemSold(item.nft, tokenId, from, SOLD);
        return true;
    }

    /**
     * 验证消息和签名
     */
    function permit(
        address nft,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, nft, tokenId, _useNonce(msg.sender))
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        return signer == _owner;
    }

    function isNFT(address contractAddress) internal view returns (bool) {
        ERC165 checker = ERC165(contractAddress);
        return
            checker.supportsInterface(_INTERFACE_ID_ERC721) ||
            checker.supportsInterface(_INTERFACE_ID_ERC1155);
    }

    function isOwner(
        address nft,
        uint256 tokenId
    ) internal view returns (bool) {
        return IERC721(nft).ownerOf(tokenId) == msg.sender;
    }

    function _buy(uint256 tokenId, Item memory item, address buyer) internal {
        address nft = item.nft;
        uint256 price = item.price;
        address seller = item.seller;
        address currency = item.currency;

        item.buyer = buyer;
        item.status = SOLD;
        saleList[nft][tokenId] = item;

        uint256 fee = (price / 1000) * defaultFeeRate;
        IERC20(currency).safeTransferFrom(buyer, seller, price - fee);
        IERC20(currency).safeTransferFrom(buyer, _treasury, fee);
        IERC721(nft).safeTransferFrom(seller, buyer, tokenId);
    }

    function _ownerCheck(address nft, uint256 tokenId) internal view {
        require(isNFT(nft), "Not NFT");
        require(isOwner(nft, tokenId), "Not Owner");
    }

    function _buyCheck(Item memory item, address buyer) internal view {
        require(isNFT(item.nft), "Not NFT");
        require(item.status == 0 || item.seller != buyer, "Can't Buy");
    }
}
