/**
 * Converts wei value into eth.
 * @param {int} value in wei
 * @returns The value of "value" in eth.
 */
function weiToEth(value) {
	return value / parseFloat(1000000000000000000n);
}

/**
 * Converts gwei value into eth.
 * @param {int} value in gwei
 * @returns The value of "value" in eth.
 */
 function gweiToEth(value) {
	return value / parseFloat(1000000000000000000n);
}

module.exports = {
	weiToEth,
	gweiToEth
}