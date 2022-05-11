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
	@dev Implementation of Lottery Token, using the [ERC721A] standard for optimized
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

	/**
	 *  
	 *	0 -> [Closed]
	 *	1 -> [Whitelist]
	 *		Ballers -> Mint (2)
	 *		Stacked -> Mint (1)
	 *	
	 * 	2 -> [Community FFA]
	 *		Ballers -> Mint (2)
	 * 		Stacked -> Mint (1)
	 *		Community -> Mint (1)
	 *		
	 *	3 -> [Public]
	 *		Everyone -> Mint (3)
	*/
	uint16 private mintingPhase = 0;

	bool private withdrawSelected = false;
	bool private isWinnerSelected = false;

	// The time at which the collection 
	uint256 private withdrawTime = 0;

	// Coupon for signature verification
	struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	enum CouponType {
		Ballers,
		Stacked,
		Community
	}

	struct Winner {
		uint winner; // winner NFT index in the ERC721A array  
		bool prizeClaimed; // was the prize already claimed?
	}

	// The list of participations
	address[] private participations;
	Winner[] private winners;

	uint16 constant NUMBER_PRIZES = 556;

	uint16 constant NUMBER_FIRST_PRIZE = 1;
	uint16 constant NUMBER_SECOND_PRIZE = 5;
	uint16 constant NUMBER_THIRD_PRIZE = 50;
	uint16 constant NUMBER_FOURTH_PRIZE = 500;

	uint16 firstPrize; // [ASSIGN] [DONE]
	uint16 secondPrize; // [ASSIGN] [DONE]
	uint16 thirdPrize; // [ASSIGN] [DONE]
	uint16 fourthPrize; // [ASSIGN] [DONE]

	// The signer address (Whitelist)
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
		@dev Function that allows minting of an NFT.
	 */
	function mint(
		address _to,
		uint _quantity,
		Coupon calldata _coupon
	) external payable {
		uint quantityCanMint = 0;

		if (!(mintingPhase == 3)) {
			require(mintingPhase > 0, "Error: Minting Closed");

			CouponType personalCoupon;
			bool couponVerified = false;
	
			bytes32 digestBallers = keccak256(abi.encode(CouponType.Ballers, _to));
			bytes32 digestStacked = keccak256(abi.encode(CouponType.Stacked, _to));
			bytes32 digestCommunity = keccak256(abi.encode(CouponType.Community, _to));

			if (_isVerifiedCoupon(digestBallers, _coupon)) {
				personalCoupon = CouponType.Ballers;
				quantityCanMint = 2;
				couponVerified = true;
			}
			else if (_isVerifiedCoupon(digestStacked, _coupon)) {
				personalCoupon = CouponType.Stacked;
				quantityCanMint = 1;
				couponVerified = true;
			}
			else if (_isVerifiedCoupon(digestCommunity, _coupon)) {
				personalCoupon = CouponType.Community;
				quantityCanMint = 1;
				couponVerified = true;
			}

			require(couponVerified, "Error: You have no key, wait for the public mint"); 

			if (mintingPhase == 1) {
				require(personalCoupon == CouponType.Ballers || personalCoupon == CouponType.Stacked);
			} 
			else if (mintingPhase == 2) {
				require(personalCoupon == CouponType.Ballers || personalCoupon == CouponType.Stacked);
			}
		
		} else require (mintingPhase == 3);

		if (mintingPhase == 3) quantityCanMint = 3;
		
		require(_quantity > 0, "Error: You need to Mint more than one Token.");
		require(_quantity + totalSupply() < 15, "Error: The quantity you're trying to mint excceeds the total supply");
		require(_quantity + _addressData[_to].numberMinted <= quantityCanMint, "Error: You can't mint that quantity of tokens.");
		require(msg.value >= ((_quantity * mintPrice) * (1 gwei)), "Error: You aren't paying enough.");
		require(withdrawTime > block.timestamp); // Minting is only possible if the withdraw time is set and is in the future.

		_mint(_to, _quantity, "", false);
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
		@dev Selects the winner and places the winners on a table.

		This function must not be callable twice. [DONE]
		This function must select the percentages that each winner gets. [DONE]

		Characteristics:
			- Only allows for withdrawing after the selected date. [DONE] 
			- The owner has a 24h grace period after that date where he can select the winner. [DONE]
			- After the owner's grace period anyone can select the winner. [DONE]
			- The winners are selected in this function. [DONE]
			- The function uses Chainlink VRF for reliable randomness instead of pseudo-reliable randomness.
	*/
	function selectWinnerWithdraw() public payable ownerCanTrigger {
		require(!isWinnerSelected); // If winner is selected can't re-run it
		
		// The owners have a 24h grace period to call it themselves
		if ((block.timestamp - withdrawTime) < 1 days) {
			require(msg.sender == owner());
		}

		uint random = block.timestamp; // TODO: This is just pseudo-randomness

		// Expand one random value into x random values by encoding and hashing
		for (uint i = 0; i < NUMBER_PRIZES; i++) {
			uint256 winnerIndex = uint256(keccak256(abi.encode(random, i))) % super.totalSupply();
			Winner memory winner = Winner(winnerIndex, false);
			winners.push(winner);
		}

		// Prize value selection logic:
		firstPrize = uint16 (address(this).balance *  90009000900090000 / 1000000000000000000);
		secondPrize = uint16 (address(this).balance * 18001800180018002 / 1000000000000000000);
		thirdPrize = uint16 (address(this).balance *  18001800180018002 / 10000000000000000000);
		fourthPrize = uint16 (address(this).balance * 18001800180018002 / 100000000000000000000);

		// Comission distribution: TODO.

		isWinnerSelected = true;
	}

	// [MOST IMPORTANT FUNCTION]
	function claimPrize() payable external {
		require(isWinnerSelected); // Require that the winner is already selected.

		uint16 totalPrize = 0;		
		for (uint i = 0; i < NUMBER_PRIZES; i++) {
			if (msg.sender == ownerOf(winners[i].winner)) {
				if (!winners[i].prizeClaimed) {
					if (i == 0) {
						totalPrize += firstPrize;
					}
					else if (i == 1 || i == 2 || i == 3 || i == 4 || i == 5) {
						totalPrize += secondPrize;
					}
					else if (i >= 6 && i <= 56) {
						totalPrize += thirdPrize;
					}
					else {
						totalPrize += fourthPrize;
					}
					
					winners[i].prizeClaimed = true;
				}
			}
		}

		// transfer prize
		if (totalPrize > 0) {
			(bool success, ) = payable(msg.sender).call{ value: totalPrize }("");
			require(success);
		}
	}

	/**
	* @dev Opens minting to public.
	*/
	function publicMint() external onlyOwner {
		mintingPhase = 3;
	}

	/**
	* @dev Opens minting for Ballers and Stacked.
	*/
	function whitelistMint() external onlyOwner {
		mintingPhase = 1;
	}

	/**
	* @dev Closes minting.
	*/
	function closeMint() external onlyOwner {
		mintingPhase = 0;
	}

	/**
	* @dev Opens minting for community, ballers and stacked.
	*/
	function communityMint() external onlyOwner {
		mintingPhase = 2;
	}

	/**
		@dev Changes the Minting price to the one specified.
		@param _mintPrice The new price for minting the token.
	*/
	function changeMintPrice(uint _mintPrice) external onlyOwner ownerCanTrigger {
		mintPrice = uint64 (_mintPrice);
	}

	/**
		@dev Sets the withdraw time and starts the lottery.
	*/
	function setWithdrawTime(uint _date) external onlyOwner {
		require(!withdrawSelected);

		withdrawSelected = true;
		withdrawTime = _date;
	}

	/* ------------------- */
	/* Auxiliary Functions */
	/* ------------------- */

	/**
		@dev Function to indicate the base URI of the metadata.
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return 'ipfs://QmNm96UyEdJgLnhuGczUna37j1PSfv42HVNkM43G2vrMaF/'; // TODO: Replace with true Metadata!
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