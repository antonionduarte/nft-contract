// SPDX-License-Identifier: Proprietary
// Creator: António Nunes Duarte;

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReducedContract is ERC721A, Ownable {
	constructor(address _signer) ERC721A("TokenWhitelist", "TKN") {
		adminSigner = _signer;
	}
	
	uint64 private mintPrice = 1000000000;

	bool private isOpenToWhitelist = false;
	bool private isOpenToPublic = false;

	struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	address private adminSigner;

	function mint(
		address _to,
		uint _quantity,
		Coupon calldata _coupon
	) public payable {
		if (!isOpenToPublic) {
			require(isOpenToWhitelist);
			bytes32 digest = keccak256(abi.encode(0, _to));
			require(_isVerifiedCoupon(digest, _coupon), "Error: Invalid Signature, you might not be registered in the WL.");
		} else require (isOpenToPublic);
		
		require(_quantity > 0, "Error: You need to Mint more than one Token.");
		require(_quantity + totalSupply() < 15, "Error: The quantity you're trying to mint excceeds the total supply");
		require(_quantity + _addressData[_to].numberMinted <= 5, "Error: You can't mint that quantity of tokens.");
		require(msg.value >= ((_quantity * mintPrice) * (1 gwei)), "Error: You aren't paying enough.");

		_mint(_to, _quantity, "", false);
	}

	function withdraw() public payable onlyOwner {
		(bool success, ) = payable(owner()).call{ value: address(this).balance }("");
		require(success);
	}

	function ownerMint(uint _quantity) external onlyOwner {
		require(_quantity > 0, "Error: You need to Mint more than one Token");
		require(_quantity + totalSupply() < 15, "Error: The quantity you're trying to mint excceeds the total supply");
		_safeMint(msg.sender, _quantity);
	}
	
	function openToWhitelist() external onlyOwner {
		isOpenToWhitelist = true;
		isOpenToPublic = false;
	}

	function openToPublic() external onlyOwner {
		isOpenToWhitelist = false;
		isOpenToPublic = true;
	}

	function closeMinting() external onlyOwner {
		isOpenToWhitelist = false;
		isOpenToPublic = false;
	}

	function changeMintPrice(uint _mintPrice) external onlyOwner {
		mintPrice = uint64 (_mintPrice);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return 'ipfs://QmNm96UyEdJgLnhuGczUna37j1PSfv42HVNkM43G2vrMaF/'; // TODO: Replace with true Metadata!!
	}

	function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon)
		internal
		view
		returns (bool)
	{
		address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
		require(signer != address(0), 'ECDSA: Invalid signature'); // Added check for zero address
		return signer == adminSigner;
	}
}
