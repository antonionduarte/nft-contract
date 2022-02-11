function serializeCoupon(coupon) {
	return {
		r: coupon.r.toString("hex"),
		s: coupon.s.toString("hex"),
		v: coupon.v
	}
}

function desserializeKey(key) {
	let divided_key = key.split("-");
	
	return {
		r: Buffer.from(divided_key[0], "hex"),
		s: Buffer.from(divided_key[1], "hex"),
		v: parseInt(divided_key[2])
	}
}

function generateKeyFromSerialized(serializedCoupon) {
	return serializedCoupon.r + "-" + serializedCoupon.s + "-" + serializedCoupon.v;
}