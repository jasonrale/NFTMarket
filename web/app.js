let wallet;
let contract;
let listMap = new Map();
const contractAddress = "0x045474b5D6578fd2b46A87321a6a2a3952c6dF13";
const abi = [
  "function listNFT(address nft, uint256 tokenId, uint256 price, address currency) external",
  "function buyNFT( address nft, uint256 tokenId) public ",
];

const connectButton = document.getElementById("connect-button");

connectButton.addEventListener("click", async () => {
  await updateWalletInfo();
});

document
  .getElementById("list-item")
  .addEventListener("submit", async (event) => {
    event.preventDefault();
    const tokenId = ethers.BigNumber.from(
      document.getElementById("token-id").value
    );
    const price = ethers.BigNumber.from(document.getElementById("price").value);
    const nftAddr = document.getElementById("nft-address").value;
    const currency = document.getElementById("currency-address").value;
    await contract.listNFT(nftAddr, tokenId, price, currency);

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
  //         await contract.buyNFT(item.tokenId, { value: item.price });
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
    address: contractAddress,
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
      contract.on("ItemListed", function (a0, a1, a2, a3, a4, a5, event) {
        decodeEvents([event.log]);
      });
      contract.on("ItemSold", function (a0, a1, a2, a3, event) {
        decodeEvents([event.log]);
      });
    } else {
      // 如果有数据则继续
      getLogs(toBlock + 1, toBlock + 1 + 2);
    }
  });
}

function decodeEvents(logs) {
  const listEvent = contract.getEvent("ItemListed").fragment;
  const soldEvent = contract.getEvent("ItemSold").fragment;

  for (var i = 0; i < logs.length; i++) {
    const item = logs[i];
    const eventId = item.topics[0]; // topic0
    if (eventId == listEvent.topicHash) {
      // listEvent Id
      const data = contract.interface.decodeEventLog(
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
      const data = contract.interface.decodeEventLog(
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
  contract = new ethers.Contract(contractAddress, abi, signer);

  connectButton.style.display = "none";
  let walletAddress = document.createElement("p");
  walletAddress.innerText = `Connected: ${account}`;
  connectButton.parentNode.appendChild(walletAddress);
}

updateItemsList();