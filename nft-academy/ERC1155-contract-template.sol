// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
    Please Read:
    This is an 1155 smart contract. It allows you to mint copies on 1 token allowing you to have 1 item on opensea and multiple owners. This is the same contract that was used for Champs Only alpha pass and very similar to what was used for NFT Academy.
    This works great for projects like Alpha Passes, where there is only 1 piece of art but multiple owners.  1155 will lower gas significantly compared to 721 contracts.

    In this contract you can create your own sale details and parameters through Remix.  When you changeSaleDetails (line 118) you are able to update TokenID, Supply, Max Per Wallet, Max Per Transaction, and Price all through remix after you deploy your contract.
    For Example if you have a whitelist with 500 supply and 1 max per wallet you can set all the details for the whitelist, then when public mint begins you can update the supply to 1500 and set max per transaction to 5.
    Play around with it if you'd like but we will do a video over 1155 contracts.

    DISCLAIMER: Please review all code and test prior to deploying live to production.
    NFT Academy will not be liable for how this code is used.
*/

//███╗░░██╗███████╗████████╗  ░█████╗░░█████╗░░█████╗░██████╗░███████╗███╗░░░███╗██╗░░░██╗
//████╗░██║██╔════╝╚══██╔══╝  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗░████║╚██╗░██╔╝
//██╔██╗██║█████╗░░░░░██║░░░  ███████║██║░░╚═╝███████║██║░░██║█████╗░░██╔████╔██║░╚████╔╝░
//██║╚████║██╔══╝░░░░░██║░░░  ██╔══██║██║░░██╗██╔══██║██║░░██║██╔══╝░░██║╚██╔╝██║░░╚██╔╝░░
//██║░╚███║██║░░░░░░░░██║░░░  ██║░░██║╚█████╔╝██║░░██║██████╔╝███████╗██║░╚═╝░██║░░░██║░░░
//╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░  ╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░░░░╚═╝░░░╚═╝░░░

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTAcademy is ERC1155Supply, Ownable
{
    bool public saleIsActive = false; //Public Mint: You must activate each sale to open up minting
    uint public activeBadgeId = 1; // - You are able to change this when you Change Sale Details (Line 118)
    uint public maxPerTransaction = 1; // this var declares the max value to mint per transaction (in this example one) - But you are able to change this when you Change Sale Details (Line 118)
    uint public maxPerWallet = 1; // variable declares the max value you can have in your wallet. I this condition is met (you have one in your wallet already) then you won't be able to mint - But you are able to change this when you Change Sale Details (Line 118)
    uint public maxSupply = 1444; // variable declares max supply limit for your project - But you are able to change this when you Change Sale Details (Line 118)
    uint public constant NUMBER_RESERVED_TOKENS = 100;  //This is where you set how many NFT's you want in your reserve (most projects use their reserved NFTs for marketing) THIS YOU CANNOT CHANGE IN SALE DETAILS
    uint256 public constant PRICE = 250000000000000000; // 0.25 ETH - The price to mint an NFT is written into the contract as WEI, but is equal to 0.25 ETH (You can check the conversion on https://eth-converter.com/). Feel free to change the price to fit your needs just make sure the value is entered as WEI in this specific contract. - But you are able to change this when you Change Sale Details (Line 118)
    string public name = "NFT Academy"; //Name of Collection

    uint public reservedTokensMinted = 0; // this is set to zero because contract has not yet been deployed and nothing has been minted yet so value starts at zero

    string public contractURIstr = "";

    constructor() ERC1155("https://ipfs.io/ipfs/QmZ5im37Mkz8k1F6ayM3WN25rcReCakXn8Wwur15rnTeN9/{id}.json") {} // this is your URI function which is inputed when contract is deployed, this is linked to the metadata share link that's uploaded on IPFS.  This can also be changed the same way you would push the URI on a 721 contract (View Live Training #1 for more info)

    //---------------------------
    //Below is a payment splitter set to pay and support the NFT Academy with 1% of initial sales from mint.
    //You can change the wallet address if you want, but if you'd like to show some love to the community we'd APPRECIATE THE SUPPORT :)
    // This is also useful if you have other partners in the project that will need to be paid out a certain percentage of mint
    //---------------------------

    address payable private recipient1 = payable(0x2E69ab2e2Ab818be7D84815e5ac29B95e46F1ef2); //partners payout address (this is NFT Academy if you'd like to support, but no pressure :) )


    function contractURI() public view returns (string memory)
    {
       return contractURIstr;
    }

    function setContractURI(string memory newuri) external onlyOwner
    {
       contractURIstr = newuri;
    }

    function setURI(string memory newuri) external onlyOwner
    {
        _setURI(newuri);
    }

    function setName(string memory _name) public onlyOwner
    {
        name = _name;
    }

    function getName() public view returns (string memory)
    {
       return name;
    }

    function mintToken(uint256 amount) external payable //This function is for Public Mint Parameters and Error Messages
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint"); //Error displays if sale is not active
        require(amount > 0 && amount <= maxPerTransaction, "Max per transaction reached, sale not allowed"); //Error displays if user mints more than max per transaction set
        require(balanceOf(msg.sender, activeBadgeId) + amount <= maxPerWallet, "Limit per wallet reached with this amount, sale not allowed"); //This limits the user from minting if they already own the NFT in their wallet. This is declared on line 23.
        require(totalSupply(activeBadgeId) + amount <= maxSupply - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply"); // If user tries to mint more than max supply (Sold Out)
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction"); //Error prints if not enough ETH to complete transaction

        _mint(msg.sender, activeBadgeId, amount, "");
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner // This function is used to mint from your reserved tokens. This variable was set on line 25.
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        _mint(to, activeBadgeId, amount, "");
        reservedTokensMinted = reservedTokensMinted + amount;
    }

    //---------------------------
    //Here is the PAYMENT SPLITTER function which is activated by "Withdraw" and is set to pay your partner a % of your project sales. // In this example it's paying us 1%
    //---------------------------


    function withdraw() external
    {
        require(msg.sender == recipient1 || msg.sender == owner(), "Invalid sender");

        uint part = address(this).balance / 100 * 1; // This is currently set to pay the NFT Academy 1% of mint sales but feel free to change the percentage and the wallet address above to fit your needs
        recipient1.transfer(part);
        payable(owner()).transfer(address(this).balance); // make sure not to remove this line as this is for withdraw DON'T REMOVE THIS LINE OR YOU WILL NOT BE ABLE TO WITHDRAW YOUR FUNDS
    }

    function flipSaleState() external onlyOwner //This function will gives you the ability to activate sales by Flipping the Sales State from False to True after you changeSaleDetails first
    {
        saleIsActive = !saleIsActive;
    }

    function changeSaleDetails(uint _activeBadgeId, uint _maxPerTransaction, uint _maxPerWallet, uint _maxSupply) external onlyOwner  //This is the function allowing you to changeSaleDetails in remix prior to flipping the sales state to active and allowing people to mint
    {
        activeBadgeId = _activeBadgeId;
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
        maxSupply = _maxSupply;
        saleIsActive = false;
    }
}
