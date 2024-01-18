// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {TestToken} from "../src/TestToken.sol";

contract NFTMarketTest is Test {
    uint8 public FOR_SALE = 0;
    uint8 public SOLD = 1;
    uint8 public CANCELED = 2;

    MyNFT public nft;
    NFTMarket public market;
    TestToken public usdt;
    uint256 public tokenId;

    address treasury = makeAddr("treasury");
    address jason = makeAddr("jason");
    address lisa = makeAddr("lisa");

    function setUp() public {
        deal(jason, 10 ether);
        deal(lisa, 10 ether);

        usdt = new TestToken();
        nft = new MyNFT();
        tokenId = nft.mint(jason,"");
        market = new NFTMarket(25, treasury);

    }

    function test_listNFT(
        uint256 price,
        address currency) public {
        
        address nftAddr = address(nft);
        vm.prank(jason);
        market.listNFT(nftAddr, tokenId, price, currency);
        NFTMarket.Item memory item = market.querySaleList(nftAddr, tokenId);

        assertEq(abi.encode(item), abi.encode(NFTMarket.Item(tokenId, nftAddr, currency, jason, address(0), FOR_SALE, price)));
    }

    function test_cancelList(
        uint256 price,
        address currency) public {
        
        address nftAddr = address(nft);
        vm.startPrank(jason);
        market.listNFT(nftAddr, tokenId, price, currency);

        market.cancelList(nftAddr, tokenId);
        vm.stopPrank();
        NFTMarket.Item memory item = market.querySaleList(nftAddr, tokenId);

        assertEq(abi.encode(item), abi.encode(NFTMarket.Item(tokenId, nftAddr, currency, jason, address(0), CANCELED, price)));
    }

    function test_buyNFT() public {
        uint256 price = 1000 * 1e18;
        address nftAddr = address(nft);

        // List NFT
        vm.startPrank(jason);
        nft.approve(address(market), tokenId);
        market.listNFT(nftAddr, tokenId, price, address(usdt));
        vm.stopPrank();

        // Mint usdt and buy NFT
        vm.startPrank(lisa);
        usdt.mint(1000 * 1e18);
        usdt.approve(address(market), price);
        market.buyNFT(nftAddr, tokenId);
        vm.stopPrank();

        NFTMarket.Item memory item = market.querySaleList(nftAddr, tokenId);

        assertEq(usdt.balanceOf(jason), 975 * 1e18);
        assertEq(usdt.balanceOf(lisa), 0);
        assertEq(usdt.balanceOf(treasury), 25 * 1e18);
        assertEq(nft.ownerOf(tokenId), lisa);
        assertEq(abi.encode(item), abi.encode(NFTMarket.Item(tokenId, nftAddr, address(usdt), jason, lisa, SOLD, price)));
    }

    function test_tokenRecieved() public {
        uint256 price = 1000 * 1e18;
        address nftAddr = address(nft);
        address marketAddr = address(market);

        // List NFT
        vm.startPrank(jason);
        nft.approve(marketAddr, tokenId);
        market.listNFT(nftAddr, tokenId, price, address(usdt));
        vm.stopPrank();

        // Mint usdt and buy NFT by tokenRecieved
        vm.startPrank(lisa);
        usdt.mint(price);
        usdt.transferWithCallback(marketAddr, price, abi.encode(NFTMarket.Item(tokenId, nftAddr, address(0), address(0), address(0), 0, 0)));
        vm.stopPrank();

        NFTMarket.Item memory item = market.querySaleList(nftAddr, tokenId);

        assertEq(usdt.balanceOf(jason), 975 * 1e18);
        assertEq(usdt.balanceOf(lisa), 0);
        assertEq(usdt.balanceOf(treasury), 25 * 1e18);
        assertEq(nft.ownerOf(tokenId), lisa);
        assertEq(abi.encode(item), abi.encode(NFTMarket.Item(tokenId, nftAddr, address(usdt), jason, lisa, SOLD, price)));
    }
}