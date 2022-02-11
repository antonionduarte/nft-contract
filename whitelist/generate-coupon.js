const {
  keccak256,
  toBuffer,
  ecsign,
} = require("ethereumjs-utils");

const { ethers } = require('ethers');

// create an object to match the contracts struct
const CouponTypeEnum = {
  Presale: 1,
};

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

module.exports = {
	generateCoupon
}