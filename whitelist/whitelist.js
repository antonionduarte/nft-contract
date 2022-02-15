const { ethers } = require("hardhat");
const { privateToAddress, bufferToHex, keccak256, toBuffer, ecsign } = require("ethereumjs-utils");

const crypto = require('crypto')

const CouponTypeEnum = {
  Presale: 0,
};

function addToWhitelist(addrStr, pvtKeyString) {
	var coupon = generateCoupon(addrStr, pvtKeyString)
	var serializedCoupon = serializeCoupon(coupon)
	var key = generateKey(serializedCoupon)
	return key;
}

function generateSigner() {
	var pvtKey = crypto.randomBytes(32);
	const pvtKeyString = pvtKey.toString("hex");
	
	const publicKey = ethers.utils.getAddress(privateToAddress(pvtKey).toString("hex"));

	return {
		private: pvtKeyString, 
		public: publicKey
	}
}

function generateCoupon(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    [CouponTypeEnum["Presale"], userAddress]
	)

	const coupon = createCoupon(hashBuffer, signerPvtKey);

	return coupon;
}

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

console.log(addToWhitelist("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199", "082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419"))
