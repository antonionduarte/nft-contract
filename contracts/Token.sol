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
contract Token is ERC721A, Ownable {
	constructor() ERC721A("Token", "TKN") {}

	// Whitelist related variables
	mapping(address => uint8) whitelistedAddresses; // address -> (uint) maxNumberTokens
	uint16 whitelistCounter; 

	// Minting related variables
	uint64 private mintPrice = 1000000000;
	uint16 private numberOfTokens = 6666; 

	bool private isOpenToWhitelist = false;
	bool private isOpenToPublic = false;

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
		require(_quantity > 0, "Error: You need to Mint more than one Token.");
		
		// TODO: Check for supply
		
		if (!isOpenToPublic) {
			if (isOpenToWhitelist) {
				require(_isWhitelisted(_to), "Error: You are not Whitelisted in this NFT Drop.");
			} else {
				require(isOpenToPublic, "Error: Not Open for Minting yet, please try again soon.");
			}
		}
		
		require(_quantity <= whitelistedAddresses[_to], "Error: You can't buy that many tokens.");
		require(_quantity + _addressData[_to].numberMinted <= whitelistedAddresses[_to], "Error: You can't mint anymore tokens.");
		require(balanceOf(_to) + _quantity <= whitelistedAddresses[_to], "Error: You can't buy that many tokens.");
		require(msg.value >= ((_quantity * mintPrice) * (1 gwei)), "Error: You aren't paying enough.");

		_safeMint(_to, _quantity);

		// TODO: Automatically handle comissions
	}

	/**
		@dev Returns the current size of the whitelist.
	*/
	function whitelistSize() external view returns (uint) {
		return whitelistCounter;
	}

	/* ------------------------ */
	/* Administrative Functions */
	/* ------------------------ */

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
		
	/**
		@dev Adds an address to the whitelist if not already added.
		The function fails if the added address was already in the whitelist.
		@param _address The address to add to the whitelist.
	*/
	function addAddressWhitelist(address _address, uint _maxNumberTokens) external onlyOwner {
		require(!_isWhitelisted(_address), "Error: Address('s) already in Whitelist");
		whitelistedAddresses[_address] = uint8 (_maxNumberTokens);
		whitelistCounter++;
	}

	/**
		@dev Adds multiple addresses to the whitelist.
		The function fails if one of the addresses is already on the whitelist.

		@param _addresses The list of addresses to add to the whitelist.
		@param _maxNumberTokens The maximum number of tokens that addresses can mint.
	*/
	function addMultipleAddressesWhitelist(address[] calldata _addresses, uint _maxNumberTokens) external onlyOwner {
		for (uint i = 0; i < _addresses.length; i++) {
			require(!_isWhitelisted(_addresses[i]));
		}

		for (uint i = 0; i < _addresses.length; i++) {
			whitelistedAddresses[_addresses[i]] = uint8 (_maxNumberTokens);
			whitelistCounter++;
		}
	}

	function updateMaxNumberTokenAddress(address _address, uint _maxNumberTokens) external onlyOwner {
		whitelistedAddresses[_address] = uint8 (_maxNumberTokens);
		if (_maxNumberTokens == 0) whitelistCounter--;
	}

	/* ------------------- /*
	/* Auxiliary Functions */
	/* ------------------- */

	/**
		@dev Function to see if a certain address is whitelisted.
	*/
	function _isWhitelisted(address _address) private view returns (bool) {
		if (whitelistedAddresses[_address] != 0) return true;

		return false;
	} 
}