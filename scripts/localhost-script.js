// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

	//const adminSigner = ethers.utils.getAddress("0x402a4189b1d72EdFBc9dfEb7771e4A5549B43531") 

  const Token = await hre.ethers.getContractFactory("LotteryToken");
  const token = await Token.deploy("0x402a4189b1d72EdFBc9dfEb7771e4A5549B43531");

  await token.deployed();

	await token.selectMintingPhase(3);

  console.log("Token deployed to:", token.address);

	const [owner, addr1, addr2, addr3] = await ethers.getSigners();
	const addr1s = await addr1.address
	console.log("addr1: " + addr1s)

	for (i = 0; i < 50; i++) {
		await token.connect(addr1).mint(addr1.address, 50, desserializeKey("be69cfbe41be2d2bbfd991a46a72a679fa29432974e97b4ff3f7512982a9313e-31364784a61270c29c4794f2ef84161e177739c4afce951cba3ab78ddfbba15e-27"), { value: ethers.utils.parseEther("5") })
	}

	console.log("test")

	for (i = 0; i < 50; i++) {
		await token.connect(addr2).mint(addr2.address, 50, desserializeKey("be69cfbe41be2d2bbfd991a46a72a679fa29432974e97b4ff3f7512982a9313e-31364784a61270c29c4794f2ef84161e177739c4afce951cba3ab78ddfbba15e-27"), { value: ethers.utils.parseEther("5") })
	}

	console.log("test")

	for (i = 0; i < 2; i++) {
		await token.connect(addr3).mint(addr3.address, 50, desserializeKey("be69cfbe41be2d2bbfd991a46a72a679fa29432974e97b4ff3f7512982a9313e-31364784a61270c29c4794f2ef84161e177739c4afce951cba3ab78ddfbba15e-27"), { value: ethers.utils.parseEther("5") })
	}

	console.log("test")

	var bal = await token.balanceOf(addr1.address)
	console.log("test " + bal)

	await token.connect(owner).selectWinnerWithdraw();
	var lol = await (await (token.connect(owner).getWinners()));
	console.log(lol);
	await token.connect(addr1).claimPrize();
  //await token.showWinners();
}

function desserializeKey(key) {
	let divided_key = key.split("-");
	
	return {
		r: "0x" + divided_key[0],
		s: "0x" + divided_key[1],
		v: parseInt(divided_key[2])
	}
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
