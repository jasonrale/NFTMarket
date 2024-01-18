// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract NFTMarket {
    using SafeERC20 for IERC20;
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

    event ItemListed(address nft, uint256 tokenId, uint256 price, address currency, address seller, uint8 status);
    event ItemSold(address nft, uint256 tokenId, address buyer, uint8 status);
    event ItemCanceled(address nft, uint256 tokenId, uint8 status);
    event onReceived(address operator, address from, uint256 tokenId, bytes data);

    constructor(uint256 feeRate, address treasury) {
        defaultFeeRate = feeRate;
        _treasury = treasury;
        _owner = msg.sender;
    }

    function querySaleList(address nft, uint256 tokenId) public view returns (Item memory) {
        return saleList[nft][tokenId];
    }

    function listNFT(
        address nft,
        uint256 tokenId,
        uint256 price,
        address currency) external {

        _ownerCheck(nft, tokenId);
        address seller = msg.sender;
        saleList[nft][tokenId] = Item(tokenId, nft, currency, seller, address(0), FOR_SALE, price);
        
        emit ItemListed(nft, tokenId, price, currency, msg.sender, FOR_SALE);
    }

    function cancelList(
        address nft,
        uint256 tokenId) external {

        _ownerCheck(nft, tokenId);
        Item memory item = saleList[nft][tokenId];
        item.status = CANCELED;

        saleList[nft][tokenId] = item;

        emit ItemCanceled(nft, tokenId, CANCELED);
    }

    function buyNFT(
        address nft,
        uint256 tokenId)
        public {

        Item memory item = saleList[nft][tokenId];
        address buyer = msg.sender;

        _buyCheck(item, buyer);
        _buy(tokenId, item, buyer);
        emit ItemSold(nft, tokenId, buyer, SOLD);
    }
 
    function tokenRecieved(address from, uint256 value, bytes memory data) external returns (bool) {
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

    function isNFT(address contractAddress) internal view returns (bool) {
        ERC165 checker = ERC165(contractAddress);
        return checker.supportsInterface(_INTERFACE_ID_ERC721) || checker.supportsInterface(_INTERFACE_ID_ERC1155);
    }

    function isOwner(address nft, uint256 tokenId) internal view returns (bool) {
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

        uint256 fee = price / 1000 * defaultFeeRate;
        IERC20(currency).safeTransferFrom(buyer, seller, price - fee);
        IERC20(currency).safeTransferFrom(buyer, _treasury, fee);
        IERC721(nft).safeTransferFrom(seller, buyer, tokenId);
    }

    function _ownerCheck(address nft, uint256 tokenId) view internal {
        require(isNFT(nft), "Not NFT");
        require(isOwner(nft, tokenId), "Not Owner");
    }

    function _buyCheck(Item memory item, address buyer) view internal {
        require(isNFT(item.nft), "Not NFT");
        require(item.status == 0 || item.seller != buyer, "Can't Buy");
    }
}