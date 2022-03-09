// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
    PLEASE READ:
    This 721 Smart Contract Template has only 2 sales "Public" and "Whitelist/Presale".
    FYI Whitelist is also named OG Sale ;)

    DISCLAIMER: Please review all code and test prior to deploying live to production.
    NFT Academy will not be liable for how this code is used.
*/


//███╗░░██╗███████╗████████╗  ░█████╗░░█████╗░░█████╗░██████╗░███████╗███╗░░░███╗██╗░░░██╗
//████╗░██║██╔════╝╚══██╔══╝  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗░████║╚██╗░██╔╝
//██╔██╗██║█████╗░░░░░██║░░░  ███████║██║░░╚═╝███████║██║░░██║█████╗░░██╔████╔██║░╚████╔╝░
//██║╚████║██╔══╝░░░░░██║░░░  ██╔══██║██║░░██╗██╔══██║██║░░██║██╔══╝░░██║╚██╔╝██║░░╚██╔╝░░
//██║░╚███║██║░░░░░░░░██║░░░  ██║░░██║╚█████╔╝██║░░██║██████╔╝███████╗██║░╚═╝░██║░░░██║░░░
//╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░  ╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░░░░╚═╝░░░╚═╝░░░

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTAcademy is ERC721, ERC721Enumerable, Ownable
{
    using Strings for string;

    uint public constant MAX_TOKENS = 4500; // Supply Limit for your collection (in this case the suppy is 4,500)
    uint public constant NUMBER_RESERVED_TOKENS = 80; //This is where you set how many NFT's you want in your reserve (most projects use their reserved NFTs for marketing)
    uint256 public constant PRICE = 80000000000000000; //0.08 - The price to mint an NFT is written into the contract as WEI, but is equal to 0.08 ETH (You can check the conversion on https://eth-converter.com/). Feel free to change the price to fit your needs just make sure the value is entered as WEI in this specific contract.

    uint public constant OG_SALE_MAX_TOKENS = 2500; // This is OG or WL Sale max supply set

    bool public saleIsActive = false; //Public Mint: You must activate each sale to open up minting it will not be active once you deploy (watch live training #1 for more details)
    bool public ogSaleIsActive = false; //Same as above


//The reason this is set at zero is because the contract has not been deployed and nothing has been minted so all values start at ZERO
    uint public reservedTokensMinted = 0;
    uint public supply = 0;
    uint public preSaleSupply = 0;
    uint public ogSaleSupply = 0;
    string private _baseTokenURI; //The Base URI is the link copied from your IPFS Folder holding your collections json files that have the metadata and image links associated to each token ID


    //---------------------------
    //Below is a payment splitter set to pay and support the NFT Academy with 1% of initial sales from mint.
    //You can change the wallet address if you want, but if you'd like to show some love to the community we'd APPRECIATE THE SUPPORT :)
    //This payment splitter is useful for paying partners a percentage of a mint
    //---------------------------
    address payable private devguy = payable(0x2E69ab2e2Ab818be7D84815e5ac29B95e46F1ef2); //Change the wallet address you want the Payment Splitter to send a set % of the mint sales too automatically once the withdraw is activated or continue supporting the NFT Academy with just 1% of sales (MORE DETAILS ON THE PAYMENT SPLITTER PROVIDED BELOW)

    constructor() ERC721("NFT Academy", "NFTAcademy") {}  //Name of Project and Token "Ticker" in this Example it's NFT Academy and NFTAcademy

    function mintToken(uint256 amount) external payable //This function is for Public Mint Parameters and Error Messages
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(amount > 0 && amount <= 5, "Max 5 NFTs per transaction"); //This is for setting the Max per transaction limit (Explainer: # of NFT's Per Transaction must be more than "0" but less than "5" or else the Error Message will Print)
        require(saleIsActive, "Sale must be active to mint"); //You must activate the sale in remix (Explainer: If SaleIsActive is False the Error Message will print)
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction"); //If the buyer does not have enough ETH is his wallet the Error Message will print

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

   //---------------------------
    //This is the OG Sale Params and Error Messages - basically the exact same function as the Public Mint above
    //---------------------------

    function mintTokenOgSale(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(ogSaleIsActive, "OG-sale must be active to mint");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(ogSaleSupply + amount <= OG_SALE_MAX_TOKENS, "Purchase would exceed max supply for OG sale");
        require(balanceOf(msg.sender) + amount <= 2, "Limit is 2 tokens per wallet, sale not allowed");

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, supply);
            supply++;
            ogSaleSupply++;
        }
    }

    function flipSaleState() external onlyOwner  //This function will gives you the ability to activate sales by Flipping the Sales State from False to True (as you see above on lines 35-38 the default is false so it must be activated to mint). You will see this "FlipSalesState" button on Remix when you deploy your contract to activate the Public Sale (You Must Flip the Sales State for Each Different Mint)
    {
        ogSaleIsActive = false;
        saleIsActive = !saleIsActive;
    }

    function flipOgSaleState() external onlyOwner //DON'T NEED TO EDIT: Same Flip Sales State function as above but this is set for the OG/WL Sales State
    {
        saleIsActive = false;
        ogSaleIsActive = !ogSaleIsActive;
    }

    function mintReservedTokens(uint256 amount) external onlyOwner //This Function is for minting your reserve which is also done through remix similar to how you flip minting sale states
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed"); //This error gets printed if you try to reserve more than what was set on the contract above

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(owner(), supply);
            supply++;
            reservedTokensMinted++;
        }
    }

    //---------------------------
    //Here is the PAYMENT SPLITTER function which is activated by "Withdraw" and is set to pay the NFT Academy 1% of sales if you'd like to show your support.
    //---------------------------

    function withdraw() external
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");

        uint devPart = address(this).balance / 100 * 1; //This is currently set to pay 1% of sales from your mint to support the NFT Academy, but can be adjusted or replaced with another wallet (Explainer: Out of the Total [100%] Contract Balance... 1% of the balance will be sent to NFTacademy wallet address on line 52)
        devguy.transfer(devPart);
        payable(owner()).transfer(address(this).balance);
    }

    ////
    //URI management functions below -- this you don't really need to touch this unless you know what you're doing, but for a quick description the "URI" is the link that connects your contract to your collections Art & Metadata folder on IPFS.
    //So when you reveal the collection after mint, you will want to update the URI link so each token/NFT can retrieve the art and metadata associated with it's ID.
    ////

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
