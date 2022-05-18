const { ethers } = require("hardhat");
const { privateToAddress, bufferToHex, keccak256, toBuffer, ecsign } = require("ethereumjs-utils");
const fs = require('fs');

const crypto = require('crypto')

const CouponTypeEnum = {
	Ballers: 0,
	Stacked: 1,
	Community: 2,
};

/**
 * The main function for creating a whitelist key.
 * @param {*} addrStr The address of the wallet to add to the whitelist.
 * @param {*} pvtKeyString The signing private key.
 * @returns The key to add to the whitelist.
 */
function addToWhitelistStacked(addrStr, pvtKeyString) {
	var coupon = generateStacked(addrStr, pvtKeyString)
	var serializedCoupon = serializeCoupon(coupon)
	var key = generateKey(serializedCoupon)
	return key;
}

function addToWhitelistBallers(addrStr, pvtKeyString) {
	var coupon = generateBallers(addrStr, pvtKeyString)
	var serializedCoupon = serializeCoupon(coupon)
	var key = generateKey(serializedCoupon)
	return key;
}

function addToWhitelistCommunity(addrStr, pvtKeyString) {
	var coupon = generateCommunity(addrStr, pvtKeyString)
	var serializedCoupon = serializeCoupon(coupon)
	var key = generateKey(serializedCoupon)
	return key;
}

/**
 * Function used to generate a signer, a pair of a public and private address.
 * @returns A dictionary containing a pair of public and private address.
 */
function generateSigner() {
	var pvtKey = crypto.randomBytes(32);
	const pvtKeyString = pvtKey.toString("hex");
	
	const publicKey = ethers.utils.getAddress(privateToAddress(pvtKey).toString("hex"));

	return {
		private: pvtKeyString, 
		public: publicKey
	}
}

/**
 * The function to generate coupons.
 */
function generateBallers(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = address //ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    	[CouponTypeEnum["Ballers"], userAddress]
	)

	const coupon = createCoupon(hashBuffer, signerPvtKey);

	return coupon;
}

function generateStacked(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = address // ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    	[CouponTypeEnum["Stacked"], userAddress]
	)

	const coupon = createCoupon(hashBuffer, signerPvtKey);

	return coupon;
}

function generateCommunity(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = address //ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    	[CouponTypeEnum["Community"], userAddress]
	)

	const coupon = createCoupon(hashBuffer, signerPvtKey);

	return coupon;
}

/* The following are helper functions to aid in coupon generation and serialization */

function createCoupon(hash, signerPvtKey) {
	return ecsign(hash, signerPvtKey);
}

function generateHashBuffer(typesArray, valueArray) {
	return keccak256(
		toBuffer(ethers.utils.defaultAbiCoder.encode(typesArray,
		valueArray))
	);
}

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

function generateKeysBallers(pvtKeyString, input) {
	const data = fs.readFileSync(input)
	const jsonString = (data.toString())
	const jsonAddresses = JSON.parse(jsonString)

	const whitelist = {
		"users": []
	}

	for (i = 0; i < jsonAddresses.addresses.length; i++) {
		try {
			const key = addToWhitelistBallers(jsonAddresses.addresses[i], pvtKeyString);
			whitelist.users.push({
				"address": jsonAddresses.addresses[i],
				"key": key
			})
		} catch (e) {
			continue
		}
	}

	return whitelist;
}

function generateKeysCommunity(pvtKeyString, input) {
	const data = fs.readFileSync(input)
	const jsonString = (data.toString())
	const jsonAddresses = JSON.parse(jsonString)

	const whitelist = {
		"users": []
	}

	for (i = 0; i < jsonAddresses.addresses.length; i++) {
		try {
			const key = addToWhitelistCommunity(jsonAddresses.addresses[i], pvtKeyString);
			whitelist.users.push({
				"address": jsonAddresses.addresses[i],
				"key": key
			})
		} catch (e) {
			continue
		}
	}

	return whitelist;
}

function generateKeysStacked(pvtKeyString, input) {
	const data = fs.readFileSync(input)
	const jsonString = (data.toString())
	const jsonAddresses = JSON.parse(jsonString)

	const whitelist = {
		"users": []
	}

	for (i = 0; i < jsonAddresses.addresses.length; i++) {
		try {
			const key = addToWhitelistStacked(jsonAddresses.addresses[i], pvtKeyString);
			whitelist.users.push({
				"address": jsonAddresses.addresses[i],
				"key": key
			})
		} catch (e) {
			continue
		}
	}

	return whitelist;
}


function concatLists(list1, list2, list3) {
	const whitelist = {
		"users": []
	}

	for (i = 0; i < list1.users.length; i++) {
		whitelist.users.push(list1.users[i]);
	}

	for (i = 0; i < list2.users.length; i++) {
		whitelist.users.push(list2.users[i]);
	}

	for (i = 0; i < list3.users.length; i++) {
		whitelist.users.push(list3.users[i]);
	}

	fs.writeFileSync('out/whitelist.json', JSON.stringify(whitelist));
}

// Runnable

//console.log(addToWhitelist("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199", "082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419"))
//const keysStacked = generateKeysStacked("082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419", "lists/stacked.json");
//const keysBallers = generateKeysBallers("082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419", "lists/ballers.json");
//const keysCommunity = generateKeysCommunity("082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419", "lists/community.json");
//concatLists(keysStacked, keysBallers, keysCommunity)
//console.log(addToWhitelistBallers("0x66a91Fc46EAe4dAf5Ad46140d6B76F43c3F0fdAc", "082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419"))
console.log(addToWhitelistBallers("0x021463e378c11B114013D9540338FEe9f5d6a7cD", "def781be48c4f6f4eeb88ff9880067ad1096831e699469f46760eb32efcb49ec-02d6271ed85c74fae0bc07dcfddde376623f396063838abb511427e1ff1ee09c-28"))