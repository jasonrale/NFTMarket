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
    uint8 public FEERATE = 25;

    MyNFT public nft;
    NFTMarket public market;
    TestToken public usdt;
    uint256 public tokenId;

    address admin;
    uint256 adminPK;
    address treasury = makeAddr("treasury");
    address jason = makeAddr("jason");
    address lisa = makeAddr("lisa");

    function setUp() public {
        (admin, adminPK) = makeAddrAndKey("admin");
        deal(admin, 1 ether);
        deal(jason, 1 ether);
        deal(lisa, 1 ether);

        vm.startPrank(admin);
        usdt = new TestToken();
        nft = new MyNFT();
        tokenId = nft.mint(jason,"");
        market = new NFTMarket(FEERATE, treasury);
        vm.stopPrank();

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

    function test_buyNFT(uint256 price) public {
        address nftAddr = address(nft);

        // List NFT
        vm.startPrank(jason);
        nft.approve(address(market), tokenId);
        market.listNFT(nftAddr, tokenId, price, address(usdt));
        vm.stopPrank();

        // Mint usdt and buy NFT
        vm.startPrank(lisa);
        usdt.mint(price);
        usdt.approve(address(market), price);
        market.buyNFT(nftAddr, tokenId);
        vm.stopPrank();

        NFTMarket.Item memory item = market.querySaleList(nftAddr, tokenId);

        uint256 fee = price / 1000 * FEERATE;
        assertEq(usdt.balanceOf(jason), price - fee);
        assertEq(usdt.balanceOf(lisa), 0);
        assertEq(usdt.balanceOf(treasury), fee);
        assertEq(nft.ownerOf(tokenId), lisa);
        assertEq(abi.encode(item), abi.encode(NFTMarket.Item(tokenId, nftAddr, address(usdt), jason, lisa, SOLD, price)));
    }

    function test_permit(address nftAddr, uint256 id) public {
        // getHash
        vm.startPrank(admin);
        bytes32 hash = market.getHash(nftAddr, id, lisa);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPK, hash);
        vm.stopPrank();

        // verify
        vm.startPrank(lisa);
        assertTrue(market.permit(nftAddr, id, v, r, s));
        vm.stopPrank();
    }

    function test_tokenRecieved(uint256 price) public {
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

        uint256 fee = price / 1000 * FEERATE;
        assertEq(usdt.balanceOf(jason), price - fee);
        assertEq(usdt.balanceOf(lisa), 0);
        assertEq(usdt.balanceOf(treasury), fee);
        assertEq(nft.ownerOf(tokenId), lisa);
        assertEq(abi.encode(item), abi.encode(NFTMarket.Item(tokenId, nftAddr, address(usdt), jason, lisa, SOLD, price)));
    }
}