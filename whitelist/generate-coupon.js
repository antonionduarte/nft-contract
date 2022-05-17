const {
  keccak256,
  toBuffer,
  ecsign,
} = require("ethereumjs-utils");

const { ethers } = require('ethers');

// create an object to match the contracts struct
const CouponTypeEnum = {
  Ballers: 0,
  Stacked: 1,
  Community: 2,
};

function generateBallers(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    [CouponTypeEnum["Presale"], userAddress]
	)

	const coupon = createCoupon(hashBuffer, signerPvtKey);

	return coupon;
}

function generateStacked(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    [CouponTypeEnum["Stacked"], userAddress]
	)

	const coupon = createCoupon(hashBuffer, signerPvtKey);

	return coupon;
}

function generateCommunity(address, signerPvtKeyString) {
	const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

	const userAddress = ethers.utils.getAddress(address);
	const hashBuffer = generateHashBuffer(
		["uint256", "address"],
    [CouponTypeEnum["Community"], userAddress]
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

module.exports = {
	generateCoupon
}