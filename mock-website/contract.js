import { ethers } from "./libs/ethers-5.1.esm.min.js";
import TokenWhitelist from '../artifacts/contracts/TokenAdvancedWhitelist.sol/TokenWhitelist.json' assert {type: 'json'}
import whitelist from './whitelist.json' assert {type: 'json'}

/* Global Variables */
var quantityToMint = 1

/* HTML Variables */
const mint_quantity_slider = document.getElementById('mint-quantity-slider');


/* ------------ */
/* Ethers Logic */
/* ------------ */

const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"

// Web3 provider
const provider = new ethers.providers.Web3Provider(window.ethereum)

await provider.send("eth_requestAccounts", [])

// get the end user
const signer = provider.getSigner();

// get the smart contract
const contract = new ethers.Contract(contractAddress, TokenWhitelist.abi, signer);

// get the balance of the connected account
const getBalance = async () => {
	const [account] = await window.ethereum.request({ method: 'eth_requestAccounts' });
	const provider = new ethers.providers.Web3Provider(window.ethereum);
	const balance = await provider.getBalance(account);
	return ethers.utils.formatEther(balance)
}

const totalMinted = async () => {
	const count = await contract.totalSupply()
	console.log(parseInt(count))
}

const tokenBalance = async () => {
	const tokenBalance = await contract.balanceOf(signer.getAddress())
	return parseInt(tokenBalance)
}

const mintTokenPublic = async (quantityToMint) => {
	const valueStr = (1.0 * quantityToMint).toString()
	const result = await contract.publicMint(signer.getAddress(), quantityToMint, {
		value: ethers.utils.parseEther(valueStr)
	})

	await result.wait()
	setTokenBalance()
}

const mintTokenWhitelist = async (quantityToMint) => {
	const valueStr = (1.0 * quantityToMint).toString()

	const addr = await signer.getAddress()
	const addrStr = addr.toString("hex")
	const key = getKey(addrStr)
	const coupon = desserializeKey(key)

	const result = await contract.whitelistMint(signer.getAddress(), quantityToMint, coupon, {
		value: ethers.utils.parseEther(valueStr)
	})

	await result.wait()
	setTokenBalance()
}

/* ---------------------- */
/* Parsing JSON Whitelist */
/* ---------------------- */

const getKey = (addrStr) => {
	let users = whitelist.users

	for (var i in users) {
		if ((users[i].address).toUpperCase() === (addrStr).toUpperCase()) {
			return users[i].key
		}
	}
}

function desserializeKey(key) {
	let divided_key = key.split("-");
	
	return {
		r: "0x" + divided_key[0],
		s: "0x" + divided_key[1],
		v: parseInt(divided_key[2])
	}
}

/* ------------------ */
/* Frontend Functions */
/* ------------------ */

async function eventListeners() {
	document.getElementById("balance-button").addEventListener('click', setBalance);
	document.getElementById("mint-button").addEventListener('click', mintWhitelist)
	document.getElementById("token-balance-button").addEventListener('click', setTokenBalance);
	document.getElementById("mint-quantity-slider").oninput = () => {
		quantityToMint = mint_quantity_slider.value
		document.getElementById("quantity-to-mint").innerHTML = quantityToMint
	}
}

async function setTokenBalance() {
	const balance = await tokenBalance()
	document.getElementById("token-balance").innerHTML = balance
}

async function setBalance() {
	const balance = await getBalance()
	document.getElementById("balance").innerHTML = balance
}

async function mintWhitelist() {
	await mintTokenWhitelist(quantityToMint)
}

async function mintPublic() {
	await mintTokenPublic(quantityToMint)
}

eventListeners()