let wallet;
let nftContract;
let nftMarketContract;
let listMap = new Map();
const nftMarketAddress = "0x045474b5D6578fd2b46A87321a6a2a3952c6dF13";
const nftABI = [
    "function approve(address to, uint256 tokenId) public",
    "function getApproved(uint256 tokenId) public view returns (address)"
];
const marketABI = [
  "function listNFT(address nft, uint256 tokenId, uint256 price, address currency) external",
  "function buyNFT( address nft, uint256 tokenId) public",
];

const connectButton = document.getElementById("connect-button");

connectButton.addEventListener("click", async () => {
  await updateWalletInfo();
});

document
  .getElementById("list-item")
  .addEventListener("submit", async (event) => {
    event.preventDefault();
    const tokenId = ethers.BigNumber.from( document.getElementById("token-id").value);
    const price = ethers.utils.parseUnits(document.getElementById("price").value, 'ether');
    const currency = document.getElementById("currency-address").value;
    const nftAddr = document.getElementById("nft-address").value;
    nftContract = new ethers.Contract(nftAddr, nftABI, signer);

    console.log(await nftContract.getApproved(1),"getinfo")
    const info=await nftContract.approve(nftMarketAddress, tokenId);
    await info.wait()
    await nftMarketContract.listNFT(nftAddr, tokenId, price, currency);

    updateItemsList();
  });

async function updateItemsList() {
  if (window.ethereum != null) {
    await updateWalletInfo();
  }

  let start = 576922;
  getLogs(start, start + 2);

  const itemsList = document.getElementById("items-list");
  itemsList.innerHTML = "";
  // items.forEach((item) => {
  //     const itemElement = document.createElement("div");
  //     itemElement.className = "item";
  //     itemElement.innerHTML = `
  //         <p>Token ID: ${item.tokenId}</p>
  //         <p>Price: ${ethers.utils.formatEther(item.price)} USDT</p>
  //         <button>Buy</button>
  //     `;
  //     itemElement.querySelector("button").addEventListener("click", async () => {
  //         await nftMarketContract.buyNFT(item.tokenId, { value: item.price });
  //         updateItemsList();
  //     });
  //     itemsList.appendChild(itemElement);
  // });
}

async function getLogs(fromBlock, toBlock) {
  const userAddress = await wallet.getAddress();

  // 定义日志过滤器，去查询我需要的数据
  let filter = {
    fromBlock,
    toBlock,
    address: nftMarketAddress,
  };

  // 检查 toBlock 是不是已经是最新的区块
  let currentBlock = await wallet.provider.getBlockNumber();

  // 如果是则获取到当前即可
  if (filter.toBlock > currentBlock) {
    filter.toBlock = currentBlock;
  }

  wallet.provider.getLogs(filter).then((logs) => {
    if (logs.length > 0) decodeEvents(logs);

    if (currentBlock <= fromBlock && logs.length == 0) {
      console.log("begin monitor");
      //监听
      nftMarketContract.on(
        "ItemListed",
        function (a0, a1, a2, a3, a4, a5, event) {
          decodeEvents([event.log]);
        }
      );
      nftMarketContract.on("ItemSold", function (a0, a1, a2, a3, event) {
        decodeEvents([event.log]);
      });
    } else {
      // 如果有数据则继续
      getLogs(toBlock + 1, toBlock + 1 + 2);
    }
  });
}

function decodeEvents(logs) {
  const listEvent = nftMarketContract.getEvent("ItemListed").fragment;
  const soldEvent = nftMarketContract.getEvent("ItemSold").fragment;

  for (var i = 0; i < logs.length; i++) {
    const item = logs[i];
    const eventId = item.topics[0]; // topic0
    if (eventId == listEvent.topicHash) {
      // listEvent Id
      const data = nftMarketContract.interface.decodeEventLog(
        listEvent,
        item.data,
        item.topics
      );
      printLog(
        `Block:${item.blockNumber} ${data.acct} ListNFT: ${data.nft} TokenId: ${
          data.tokenId
        } Price: ${ethers.formatEther(data.price)} Currency: ${
          data.currency
        } Seller: ${data.a4} State: ${data.a5} (${item.transactionHash})`
      );
    }
    if (eventId == withdrawEvent.topicHash) {
      // soldEvent Id
      const data = nftMarketContract.interface.decodeEventLog(
        soldEvent,
        item.data,
        item.topics
      );
      printLog(
        `Block:${item.blockNumber} ${data.acct} SoldNFT ${ethers.formatEther(
          data.amount
        )} $TEST (${item.transactionHash})`
      );
    }
  }
}

function printLog(msg) {
  let p = document.createElement("p");
  p.textContent = msg;
  document.getElementsByClassName("logs")[0].appendChild(p);
}

async function updateWalletInfo() {
  let provider = new ethers.providers.Web3Provider(window.ethereum);
  const accounts = await ethereum.request({ method: "eth_requestAccounts" });
  const account = accounts[0];
  signer = provider.getSigner(account);
  wallet = signer;
  nftMarketContract = new ethers.Contract(nftMarketAddress, marketABI, signer);

  connectButton.style.display = "none";
  let walletInfoDiv = document.getElementById("wallet-info");
  let walletAddress = walletInfoDiv.querySelector("p");
  if (!walletAddress) {
    walletAddress = document.createElement("p");
    connectButton.parentNode.appendChild(walletAddress);
  }
  walletAddress.innerText = `Connected: ${account}`; 
}

updateItemsList();