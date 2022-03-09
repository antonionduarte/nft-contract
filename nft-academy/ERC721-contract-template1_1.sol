// SPDX-License-Identifier: MIT
pragma solidity 0.8.9; //Compiler

/**
    PLEASE READ:
    This 721 Smart Contract Template is the same contract that I used for
    the Magic Mushroom Clubhouse Collection. Now there are many different ways to write a Smart Contract
    and I’m sure some great developers in our discord will critique it and have some great ways
    to improve and optimize this contract.

    However due to the fact this was my first ever smart contract ;) I thought it would be
    fun to share and look back on.

    This 721 contract has been tested and deployed to production,
    and is being used on Magic Mushroom Clubhouse so YES IT DOES WORK.
    When it comes to needing very basic contract functionality this will work
    for your project or can be used as a framework to build off of.

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

contract MagicMushroomClubhouse is ERC721, ERC721Enumerable, Ownable //You can change the contract title to whatever you want it's just currently set as "MagicMushroomClubhouse" in this example
{
    using Strings for string;

    uint public constant MAX_TOKENS = 9200; //This is your Supply Limit for your project (in this case the supply is set to 9,200 Editions)
    uint public constant NUMBER_RESERVED_TOKENS = 100; //This is where you set how many NFT's you want in your reserve (most projects use their reserved NFTs for marketing)
    uint256 public constant PRICE = 50000000000000000; // 0.05 ETH - The price to mint an NFT is written into the contract as WEI, but is equal to 0.05 ETH (You can check the conversion on https://eth-converter.com/). Feel free to change the price to fit your needs just make sure the value is entered as WEI in this specific contract.

    uint public constant WL_SALE_MAX_TOKENS = 2000; //This is your WhiteList Max Supply Set (Example: if you have 1,000 WL Spots and each person is guaranteed 2 your supply would be set to 2,000) FYI: Any tokens that don't sell get rolled into the Public Mint
    uint public constant PRE_SALE_MAX_TOKENS = 2500; //This is your PreSale Max Supply Set (We typically use the Presale in between WL and Public Mint to gauge projections for Public Mint Day in case we need to delay mint to run more marketing hype and it benefits your community more for those who were not able to get access to the WL) it also can be used to drive more organic incentives inside your community

    bool public saleIsActive = false; //Public Mint: You must activate each sale to open up minting
    bool public wlSaleIsActive = false; //WL Mint
    bool public preSaleIsActive = false; //PreSale Mint

    //The reason this is set at zero is because the contract has not been deployed and nothing has been minted so all values start at ZERO
    uint public reservedTokensMinted = 0;
    uint public supply = 0;
    uint public preSaleSupply = 0;
    uint public wlSaleSupply = 0;
    string private _baseTokenURI; //The Base URI is the link copied from your IPFS Folder holding your collections json files that have the metadata and image links associated to each token ID

    //---------------------------
    //Below is a payment splitter set to pay and support the NFT Academy with 1% of initial sales from mint.
    //You can change the wallet address if you want, but if you'd like to show some love to the community we'd APPRECIATE THE SUPPORT :)
    //---------------------------

    address payable private NFTacademy = payable(0x2E69ab2e2Ab818be7D84815e5ac29B95e46F1ef2); //Change the wallet address you want the Payment Splitter to send a set % of the mint sales too automatically once the withdraw is activated or continue supporting the NFT Academy with just 1% of sales (MORE DETAILS ON THE PAYMENT SPLITTER PROVIDED BELOW)

    constructor() ERC721("Magic Mushroom Clubhouse", "SHROOM") {} //Name of Project and Token "Ticker" in this Example it's Magic Mushroom Clubhouse and SHROOM

    function mintToken(uint256 amount) external payable //This function is for Public Mint Parameters and Error Messages
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(amount > 0 && amount <= 10, "Max 10 NFTs per transaction"); //This is for setting the Max per transaction limit (Explainer: # of NFT's Per Transaction must be more than "0" but less than "10" or else the Error Message will Print)
        require(saleIsActive, "Public Sale must be active to mint"); //You must activate the sale in remix (Explainer: If SaleIsActive is False the Error Message will print)
        require(supply + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply"); //If the supply sold reaches the MAX_TOKENS (Line 31) including the reserve set (Line 32) the Error Message will print (This keeps people from minting above the set supply of your collection)
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction"); //If the buyer does not have enough ETH is his wallet the Error Message will print

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

    //---------------------------
    //This is the WhiteList Parameters and Error Messages - basically the exact same function as the Public Mint above
    //---------------------------

    function mintTokenWlSale(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(wlSaleIsActive, "Whitelist Sale must be active to mint");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(wlSaleSupply + amount <= WL_SALE_MAX_TOKENS, "Purchase would exceed max supply for Whitelist Sale");
        require(balanceOf(msg.sender) + amount <= 2, "Limit is 2 tokens per wallet, this sale not allowed"); //This limits the user from minting if they already own 2 NFTs/Tokens in their wallet. Set a limit of how many NFT's a user can mint per wallet instead of transaction by changing the number (... amount <= __)

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, supply);
            supply++;
            wlSaleSupply++;
        }
    }

    //---------------------------
    //This is the PreSale Parameters and Error Messages - basically the exact same function as the WL Mint above
    //---------------------------

    function mintTokenPreSale(uint256 amount) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(preSaleIsActive, "Pre Sale must be active to mint");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(preSaleSupply + amount <= PRE_SALE_MAX_TOKENS, "Purchase would exceed max supply for pre sale");
        require(balanceOf(msg.sender) + amount <= 5, "Limit is 5 tokens per wallet, this sale not allowed"); //5 Per wallet is the max for presale vs 2 for Whitelist

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(msg.sender, supply);
            supply++;
            preSaleSupply++;
        }
    }

    function flipSaleState() external onlyOwner //This function will gives you the ability to activate sales by Flipping the Sales State from False to True (as you see above on lines 38-40 the default is false so it must be activated to mint). You will see this "FlipSalesState" button on Remix when you deploy your contract to activate the Public Sale (You Must Flip the Sales State for Each Different Mint)
    {
        preSaleIsActive = false;
        wlSaleIsActive = false;
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner //DON'T NEED TO EDIT: Same Flip Sales State function as above but this is set for the Presale (If for some reason you don't need a Presale you can just skip the presale and never activate the sale, and go from WL directly to Public Mint... I just wanted to add the Presale in case you'd like to use it because it's worked well for us)
    {
        saleIsActive = false;
        wlSaleIsActive = false;
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWlSaleState() external onlyOwner //DON'T NEED TO EDIT: Same Flip Sales State function as above but this is set for the Whitelist
    {
        saleIsActive = false;
        preSaleIsActive = false;
        wlSaleIsActive = !wlSaleIsActive;
    }

    function mintReservedTokens(uint256 amount) external onlyOwner //This Function is for minting your reserve which is also done through remix similar to how you flip minting sale states
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

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
        require(msg.sender == NFTacademy || msg.sender == owner(), "Invalid sender");

        uint devPart = address(this).balance / 100 * 1; //This is currently set to pay 1% of sales from your mint to support the NFT Academy, but can be adjusted or replaced with another wallet (Explainer: Out of the Total [100%] Contract Balance... 1% of the balance will be sent to NFTacademy wallet address on line 54)
        NFTacademy.transfer(devPart);
        payable(owner()).transfer(address(this).balance); //Don't remove this line or you will not be able to withdraw your funds from the contract
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
