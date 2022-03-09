const { expect } = require("chai");
const { ethers } = require("hardhat"); 

describe("Lottery", () => {
	let contact;
	let mintingKey;
	let whitelistKey;
	
	beforeEach(async () => {
		const accounts = await ethers.getSigners();
		mintingKey = accounts[0]
		whitelistKey = accounts[1]
		
		const Token = await ethers.getContractFactory('')
	})

	it("Correct Public Minting Test - Lottery", async () => {
		
	});

	it("Correct Whitelist Minting Test - Lottery", async () => {
		
	});
	
	it("Wrong price test - Lottery", async () => {

	});

	it("Too many  - Lottery", async () => {

	});
})