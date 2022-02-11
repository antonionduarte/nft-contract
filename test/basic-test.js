const { expect } = require("chai");
const { ethers } = require("hardhat"); 

const conversion = require("./eth-conversions");

describe("Token", function () {
  it("Test basic functionality", async function () {
    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy();
    await token.deployed();

		const recipient = "0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199";
		
		// Balance expected to be 0
		let balance = await token.balanceOf(recipient);
		expect(balance).to.equal(0);
		console.log("Recipient Balance: " + balance)

		// await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1") }) // Should fail if uncommented

		// Opens for minting
		await token.openToWhitelist();

		// await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1") }) // Should fail if uncommented

		// Adds address to whitelist
		await token.addAddressWhitelist("0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199", 2);
		
		const mintedToken = await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1") })

		let contractBalance = await token.contractBalance();
		console.log("Contract  Balance: " + conversion.weiToEth(contractBalance) + " Eth");
		
		// Publicly mints the token
		await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1") })
		let newBalance = await token.balanceOf(recipient);

		console.log("New balance recipient: " + newBalance)

		// await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1") }) // Should fail if uncommented

		await token.closeMinting();
		// await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1") }) // Should fail if uncommented
		await token.openToWhitelist();
  
		await token.updateMaxNumberTokenAddress(recipient, 5);
		// await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("0.9") }) // Should fail if uncommented
		await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("1.0") })

		await token.changeMintPrice("900000000");
		await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("0.9") })
		// await token.publicMint(recipient, 1, { value: ethers.utils.parseEther("0.8") }) // Should fail if uncommented

		contractBalance = await token.contractBalance();
		console.log("Contract  Balance: " + conversion.weiToEth(contractBalance) + " Eth");

		await token.withdraw();
		let finalBalance = await token.contractBalance();
		console.log("Final Contract  Balance: " + conversion.weiToEth(finalBalance) + " Eth");

	});
});