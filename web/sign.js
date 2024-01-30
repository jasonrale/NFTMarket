const ethers = require('ethers');
require('dotenv').config();

const contractAbi = [
    "function getHash(address nft, uint256 tokenId, address wlUser) public view returns (bytes32)",
    "function buyNFTForWL(address nft, uint256 tokenId, uint8 v, bytes32 r, bytes32 s) public",
  ];

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY);
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.blast.io/');
const contract = new ethers.Contract(process.env.NFT_MARKET_CONTRACT, contractAbi, wallet.connect(provider));

async function run() {
    const nftAddr = process.env.NFT_CONTRACT;
    const hash = await contract.getHash(nftAddr, 1, "0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8");

}

run();