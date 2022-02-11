const { expect } = require("chai");
const { ethers } = require("hardhat"); 
const { privateToAddress, bufferToHex } = require("ethereumjs-utils");

const crypto = require("crypto");
const signature = require("../whitelist/generate-coupon");
const fs = require('fs')

describe("Token", function () {
  it("Test advanced whitelisting functionality", async function () {
		const accounts = await ethers.getSigners();
    let mintingKey = "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199";
		let maliciousMinter = "0xdd2fd4581271e230360230f9337d5c0430bf44c0";
    
		// Whitelist key
		const pvtKey = crypto.randomBytes(32);
		const pvtKeyString = pvtKey.toString("hex");
		const signerAddress = ethers.utils.getAddress(privateToAddress(pvtKey).toString("hex"));

		const receiver = ethers.utils.getAddress(mintingKey);

		const Token = await ethers.getContractFactory("TokenWhitelist");
    const token = await Token.deploy(signerAddress);
    await token.deployed();

    const coupon = signature.generateCoupon(mintingKey, pvtKeyString);
		// console.log(coupon);
		//console.log(auxCoupon);

		let serializedCoupon = serializeCoupon(coupon);
		let key = generateKey(serializedCoupon);
		console.log(key);

		let dKey = desserializeKey(key)

		// await token.whitelistMint(sig);
		token.openToWhitelist();
		token.whitelistMint(receiver, 1, dKey);
	});
});

function serializeCoupon(coupon) {
	return {
		r: coupon.r.toString("hex"),
		s: coupon.s.toString("hex"),
		v: coupon.v
	}
}

function generateKey(serializedCoupon) {
	return serializedCoupon.r + "-" + serializedCoupon.s + "-" + serializedCoupon.v;
}

function desserializeKey(key) {
	let divided_key = key.split("-");
	
	return {
		r: Buffer.from(divided_key[0], "hex"),
		s: Buffer.from(divided_key[1], "hex"),
		v: parseInt(divided_key[2])
	}
}