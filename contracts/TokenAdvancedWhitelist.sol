// SPDX-License-Identifier: Proprietary
// Creator: António Nunes Duarte;

pragma solidity ^0.8.0;

// Imports
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
	@dev Implementation of BlackGold Token, using the [ERC721A] standard for optimized
	gas costs, specially when batch minting Tokens.

	This token works exclusively in a Whitelist so there is no need to close and open whitelist.
 */
contract TokenWhitelist is ERC721A, Ownable {
	constructor(address _adminSigner) ERC721A("TokenWhitelist", "TKN") {
		adminSigner = _adminSigner;
	}
	
	// Minting related variables
	uint64 private mintPrice = 1000000000;
	uint16 private numberOfTokens = 6666;
	uint16 private maxNumberMints = 6666;

	bool private isOpenToWhitelist = false;
	bool private isOpenToPublic = false;

	// Coupon for signature verification
	struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	enum CouponType {
		Presale
	}

	address private adminSigner;

	/* ---------------- */
	/* Public Functions */
	/* ---------------- */

	/**
		@dev The publicMint function, that requires a payment.
		@param _quantity The quantity of NFTs that are trying to be minted.
	*/
	function publicMint(
		address _to,
		uint _quantity
	) external payable {
		require(isOpenToPublic, "Error: The NFT isn't open for public minting yet.");
		require(_quantity > 0, "Error: You need to Mint more than one Token.");
		require(_quantity + totalSupply() < numberOfTokens, "Error: The quantity you're trying to mint excceeds the total supply");
		require(_quantity + _addressData[_to].numberMinted <= maxNumberMints, "Error: You can't mint that quantity of tokens.");
		require(msg.value >= ((_quantity * mintPrice) * (1 gwei)), "Error: You aren't paying enough.");

		_safeMint(_to, _quantity);

		// TODO: Automatically handle comissions.
	}

	/**
		@dev The function to use when minting during opened whitelist.
		@param _quantity The quantity of NFTs to mint.
		@param _coupon The coupon to validate the whitelist spot.
	*/
	function whitelistMint(
		address _to,
		uint _quantity,
		Coupon memory _coupon
	) external payable {
		require(isOpenToWhitelist);
		require(_quantity > 0, "Error: You need to Mint more than one Token.");
		require(_quantity + totalSupply() < numberOfTokens, "Error: The quantity you're trying to mint excceeds the total supply");
		require(_quantity + _addressData[_to].numberMinted <= maxNumberMints, "Error: You can't mint that quantity of tokens.");	
		require(msg.value >= ((_quantity * mintPrice) * (1 gwei)), "Error: You aren't paying enough.");

		bytes32 digest = keccak256(abi.encode(CouponType.Presale, _to));
		require(_isVerifiedCoupon(digest, _coupon), "Error: Invalid Signature, you might not be registered in the WL.");

		_safeMint(_to, _quantity);

		// TODO: Automatically handle comissions.
	}

	/* ------------------------ */
	/* Administrative Functions */
	/* ------------------------ */

	/**
		* @dev Changes the address of admin signer. 
	*/
	function changeAdminSigner(address _adminSigner) external onlyOwner {
		adminSigner = _adminSigner;
	}

	/**
	 * @dev Returns the chainid of the contract.
	*/
	function contractChain() external view onlyOwner returns (uint) {
		return block.chainid;
	}

	/**
	 * @dev Allows changing the maximum number of tokens. 
	*/
	function changeNumberTokens(uint16 _numberOfTokens) external onlyOwner {
		numberOfTokens = _numberOfTokens;
	}

	/** 
		@dev Returns the current balance of the smart contract.
	*/
	function contractBalance() external view onlyOwner returns (uint) {
		return address(this).balance;
	}

	/**
		@dev Transfers funds to a specific wallet.
	*/
	function withdraw() public payable onlyOwner {
		(bool success, ) = payable(owner()).call{ value: address(this).balance }("");
		require(success);
	}

	/**
		@dev Exclusive function for the owner to mint tokens.
		@param _quantity The quantity of NFTs that are trying to be minted.
	*/
	function ownerMint(uint _quantity) external onlyOwner {
		require(_quantity > 0, "Error: You need to Mint more than one Token");
		require(_quantity + totalSupply() < numberOfTokens, "Error: The quantity you're trying to mint excceeds the total supply");
		_safeMint(msg.sender, _quantity);
	}
	
	/**
		@dev Opens the Token for Minting to Whitelist. 
	*/
	function openToWhitelist() external onlyOwner {
		isOpenToWhitelist = true;
		isOpenToPublic = false;
	}

	/**
		@dev Opens the Token for Minting to Public.
	*/
	function openToPublic() external onlyOwner {
		isOpenToWhitelist = false;
		isOpenToPublic = true;
	}

	/**
		@dev Closes the Token for Minting.
		Closes it both for Whitelist and Public.
	*/
	function closeMinting() external onlyOwner {
		isOpenToWhitelist = false;
		isOpenToPublic = false;
	}

	/**
		@dev Changes the Minting price to the one specified.
		@param _mintPrice The new price for minting the token.
	*/
	function changeMintPrice(uint _mintPrice) external onlyOwner {
		mintPrice = uint64 (_mintPrice);
	}

	/* ------------------- */
	/* Auxiliary Functions */
	/* ------------------- */

	/**
		@dev Function to indicate the base URI of the metadata.
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return 'ipfs://PLACE-URI-HERE'; // TODO!
	}

	/**
	 	@dev check that the coupon sent was signed by the admin signer
	*/
	function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon)
		internal
		view
		returns (bool)
	{
		// address signer = digest.recover(signature);
		address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
		require(signer != address(0), 'ECDSA: Invalid signature'); // Added check for zero address
		return signer == adminSigner;
	}
}
