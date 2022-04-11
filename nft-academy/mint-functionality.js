

const maxNFT = 3 //Max NFTs per transaction
const buttonId = "connect" //This is the button ID you need to link which will change from connect wallet to mint now
const contractAddress = "Contract Address Goes Here" //Enter contract address
const cost = 0.25 //Cost
const nftNumField = document.getElementById("Quantity-2")
const wl = false //Whitelist is False because this is set for public mint page

//fixed stuff
var bt = document.getElementById(buttonId)
bt.removeAttribute("href")
bt.style.cursor = 'pointer'

const supplyElement = document.getElementById("supply")
supplyElement.innerHTML = "Amount sold: please connect your wallet to see it" //Count Tracker to show how many are sold
var supply = 1444 //Total Supply

function changePrice()
{
  var priceEl = document.getElementById("price")
  priceEl.innerHTML = (0.25 * nftNumField.value).toFixed(2) + " ETH"
}

nftNumField.onchange = changePrice

var nftNum = 1

function setNftNum()
{
    var str = nftNumField.value
    var n = Math.floor(Number(str))

    if (n !== Infinity && String(n) === str && n > 0)
    {
        if (n > maxNFT)
        {
            alert("Num of NFTs should be <= " + maxNFT.toString())
            nftNumField.value = "1"
            nftNum = 1
            return false
        }
        else nftNum = n
    }
    else
    {
        alert("Num of NFTs should be > 0")
        nftNumField.value = "1"
        nftNum = 1
        return false
    }
    return true
}

var abi = []
var signer
var provider

async function connect()
{
    if (!window.ethereum) {
        alert("No wallet installed. Please install a wallet on the browser - MetaMask is preferred!")
        return
    }

    provider = await new ethers.providers.Web3Provider(window.ethereum, "any")
    await provider.send("eth_requestAccounts", [])

    signer = provider.getSigner()
    var address = await signer.getAddress()
    //getSupply()

    if (wl)
    {
        var req = new XMLHttpRequest()
        req.open("POST", 'https://1bmcx1sc46.execute-api.us-west-2.amazonaws.com/default/whitelist?champAdd=' + address, true)
        req.setRequestHeader("Content-Type", "application/json charset=UTF-8")
        req.send()

        req.onreadystatechange = function ()
        {
            if (req.readyState == 4 && req.status == 200)
            {
                if (req.response === "ok")
                {
                    bt.innerHTML = "Mint Token"
                    bt.onclick = mintToken
                    abi = [{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintToken","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
                }
                else alert("Address not whitelisted. Sorry, you can't mint")
            }
        }
    } else {
        bt.innerHTML = "Mint Token"
        bt.onclick = mintToken
        abi = [{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintToken","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
    }

    setTimeout(function() {
        getSupply()
    }, 2000)
}

async function getSupply()
{
    //var signer = provider.getSigner()
    var address = await signer.getAddress()

    var contract = new ethers.Contract(contractAddress, abi, signer)

    contract.totalSupply("1").then((res) =>
    {
        supplyElement.innerHTML = "Amount Sold: " + res + " out of " + supply.toString()
    })
}

async function mintToken()
{
    getSupply()
    if (!setNftNum()) return

    var contract = new ethers.Contract(contractAddress, abi, signer)
    var overrides = { value: ethers.utils.parseEther((nftNum * cost).toString()) }

    contract.mintToken(nftNum, overrides).then((res) =>
    {
        alert("Token being minted! After receiving confirmation from your wallet, you can see it at Opensea or on your wallet")
    }
    ).catch(function (e) {
        if (JSON.stringify(e).indexOf ("must be active") > -1)
        {
        alert("Sorry, sale is not active right now.")
        }
        else if (JSON.stringify(e).indexOf ("insufficient funds") > -1)
        {
        alert("Sorry, seems your wallet doesn't have enough funds to make this purchase!")
        }
        else if (JSON.stringify(e).indexOf ("Max NFT") > -1)
        {
        alert("Sorry, purchase would exceed limit per wallet!")
        }
        else if (JSON.stringify(e).indexOf ("would exceed max supply") > -1)
        {
        alert("Sorry, sold out!")
        }
        else if (JSON.stringify(e).indexOf ("Address not whitelisted") > -1)
        {
        alert("Sorry, address not whitelisted!")
        }
        else
        {
            alert("Sorry, we had an error with your transaction. " + JSON.parse(e.message.split("rror=")[1].split(", method")[0]).message)
        }
    })
}

bt.onclick = connect