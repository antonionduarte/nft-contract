const hre = require('hardhat')

async function main() {
  const Token = await hre.ethers.getContractFactory("TokenWhitelist");

	const contract = Token.attach(
		"0x5FbDB2315678afecb367f032d93F642f64180aa3"
	);

	//var thing = await contract.selectWinnerWithdraw();
	var thing2 = await contract.distributeComissions();
	//console.log(thing2); 
}