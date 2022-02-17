// SPDX-License-Identifier: Proprietary
// Creator: António Nunes Duarte;

pragma solidity ^0.8.0;

// Imports
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "hardhat/console.sol";

/**
	@dev Implementation of BlackGold Token, using the [ERC721A] standard for optimized
	gas costs, specially when batch minting Tokens.

	This token works exclusively in a Whitelist so there is no need to close and open whitelist.
 */
contract LotteryToken is ERC721A, Ownable, VRFConsumerBaseV2 {
	constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) ERC721A("TokenWhitelist", "TKN") {
		COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
		adminSigner = msg.sender;
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
	}

	// Chainlink related configs.
	// TODO: Change them to work for the Mainnet.
	VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
	

	uint64 s_subscriptionId;

	address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // TODO: Currently set for Rinkeby, change for Mainnet.
	address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
	bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
	uint32 numWords =  1;

	uint256[] public s_randomWords; // Where the random values are stored 

  uint256 public s_requestId;
  address s_owner;
	
	// Minting related variables
	uint64 private mintPrice = 1000000000;
	uint16 private numberOfTokens = 15;
	uint16 private maxNumberMints = 5; 

	bool private isOpenToWhitelist = false;
	bool private isOpenToPublic = false;

	// The time at which the collection 
	uint256 private withdrawTime = 0;

	// The list of participations
	address[] private participations;

	// Coupon for signature verification
	struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	enum CouponType {
		Presale
	}

	// The signer address
	address private adminSigner;

	/* ------------------- */
	/* Chainlink Functions */
	/* ------------------- */

	// Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

	/* ---------------- */
	/* Public Functions */
	/* ---------------- */

	/**
		@dev The publicMint function, that requires a payment.
		@param _quantity The quantity of NFTs that are trying to be minted.
		TODO: Make it so minting can only be done if if the withdraw time is in the future.
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

		// TODO: Make it so minting can only be done if the withdraw time is in the future.
		// TODO: Add address to the participations 
		require(withdrawTime > block.timestamp); // Minting is only possible if the withdraw time is set and is in the future.
		participations.push(_to);

		_mint(_to, _quantity, "", false);

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

		// TODO: Make it so minting can only be done if if the withdraw time is in the future.
		// TODO: Add address to the participations
		require(withdrawTime > block.timestamp); // Minting is only possible if the withdraw time is set and is in the future.
		participations.push(_to);

		// Checking for whitelist key validity
		bytes32 digest = keccak256(abi.encode(CouponType.Presale, _to));
		require(_isVerifiedCoupon(digest, _coupon), "Error: Invalid Signature, you might not be registered in the WL.");

		_mint(_to, _quantity, "", false);

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
	 * @dev Allows changing the maximum number of tokens. 
	*/
	function changeNumberTokens(uint16 _numberOfTokens) external onlyOwner ownerCanTrigger {
		numberOfTokens = _numberOfTokens;
	}

	/**
		@dev Transfers funds to a specific wallet.
		TODO: Change this function to do what was specified.
		- Only allows for withdrawing after the selected date.
		- The owner has a 24h grace period after that date where he can select the winner.
		- After the owner's grace period anyone can select the winner.
		- The winners are selected in this function, and their prizes are automatically distributed.
		- The function uses Chainlink VRF for reliable randomness instead of pseudo-reliable randomness.
	*/
	function selectWinnerWithdraw() public payable {
		require(block.timestamp < withdrawTime); // Can't trigger while lottery is ongoing
		
		// The owners have a 24h grace period to call it themselves
		if ((block.timestamp - withdrawTime) < 1 days) {
			require(msg.sender == owner());
		}

		uint random = block.timestamp; // TODO: This is just pseudo-randomness
		uint numberWinners = 10;

		uint256[] memory expandedValues;

		// Expand one random value into 10 random values by hashing
		for (uint i = 0; i < numberWinners; i++) {
			expandedValues[i] = uint256(keccak256(abi.encode(random, i))) % participations.length;
		}

		// TODO: Delete, just for testing purposes
		for (uint i = 0; i < numberWinners; i++) {
			console.log(expandedValues[i]);
		}

		// First place - One winner - 50%
		address firstPlace = participations[expandedValues[0]];

		// Second place - Three winners - 20 %
		address secondPlace = participations[expandedValues[1]];
		address thirdPlace = participations[expandedValues[2]];
		address fourthPlace = participations[expandedValues[3]];
		
		// Third place - Six winners - 10% 
		address fifthPlace = participations[expandedValues[4]];
		address sixthPlace = participations[expandedValues[5]];
		address seventhPlace = participations[expandedValues[6]];
		address eighthPlace = participations[expandedValues[7]];
		address ninthPlace = participations[expandedValues[8]];
		address tenthPlace = participations[expandedValues[9]];

		// Comissions - Remaining 20%
		// TODO: Comission Addresses

		uint firstPlaceValue = (address(this).balance * 5 / 100);
		uint secondPlaceValue = (address(this).balance * 2 / 100) / 3;
		uint thirdPlaceValue = (address(this).balance * 1 / 100) / 6;

		// Payment distribution logic
		(bool success, ) = payable(firstPlace).call{ value: firstPlaceValue }("");
		(success, ) = payable(secondPlace).call{ value: secondPlaceValue }("");
		(success, ) = payable(thirdPlace).call{ value: secondPlaceValue }("");
		(success, ) = payable(fourthPlace).call{ value: secondPlaceValue }("");
		(success, ) = payable(fifthPlace).call{ value: thirdPlaceValue }("");
		(success, ) = payable(sixthPlace).call{ value: thirdPlaceValue }("");
		(success, ) = payable(seventhPlace).call{ value: thirdPlaceValue }("");
		(success, ) = payable(eighthPlace).call{ value: thirdPlaceValue }("");
		(success, ) = payable(ninthPlace).call{ value: thirdPlaceValue }("");
		(success, ) = payable(tenthPlace).call{ value: thirdPlaceValue }("");

		// Comission distribution logic
		// TODO: Send a percentage to me
		// TODO: All the rest of the money goes to the devs, if one of the payments failed they can manually
		// 			 Take care of finishing it later.
	}
	
	/**
		@dev Opens the Token for Minting to Whitelist. 
		TODO: Owner can't trigger this function after a certain time
	*/
	function openToWhitelist() external onlyOwner ownerCanTrigger {
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
		TODO: Owner can't trigger this function after a certain time
	*/
	function closeMinting() external onlyOwner ownerCanTrigger {
		isOpenToWhitelist = false;
		isOpenToPublic = false;
	}

	/**
		@dev Changes the Minting price to the one specified.
		@param _mintPrice The new price for minting the token.
		// TODO: Owner can't trigger this function after a certain time
	*/
	function changeMintPrice(uint _mintPrice) external onlyOwner ownerCanTrigger {
		mintPrice = uint64 (_mintPrice);
	}

	/**
		@dev Sets the withdraw time and starts the lottery.
		// TODO: Owner can't trigger this function after a certain time-
	*/
	function setWithdrawTime(uint _date) external onlyOwner ownerCanTrigger {
		withdrawTime = _date;
	}

	/* ------------------- */
	/* Auxiliary Functions */
	/* ------------------- */

	/**
		@dev Function to indicate the base URI of the metadata.
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return 'ipfs://QmNm96UyEdJgLnhuGczUna37j1PSfv42HVNkM43G2vrMaF/'; // TODO: Replace with true Metadata!!
	}

	/**
	 	@dev check that the coupon sent was signed by the admin signer
	*/
	function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon)
		internal
		view
		returns (bool)
	{
		address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
		require(signer != address(0), 'ECDSA: Invalid signature'); // Added check for zero address
		return signer == adminSigner;
	}

	/* --------- */
	/* Modifiers */
	/* --------- */

	/**
		@dev Modifier to ensure that the owner can only trigger the function before the lottery starts.
	*/
	modifier ownerCanTrigger() {
		require(withdrawTime < block.timestamp, "Lottery: You can't trigger the function before the lottery ends.");
		_;
	}


}
