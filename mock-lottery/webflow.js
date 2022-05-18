<script src="https://cdn.ethers.io/lib/ethers-5.1.umd.min.js" charset="utf-8" type="text/javascript"></script>

<script type="text/javascript">
	
</script>

<script>
	let whitelist;
  let abi;
  let contract;
  let signer;
  let provider;
  let contractAddress = "0xBdC327Eee4E54779a3337Ee18da164e5755E78e6"

	async function main() {
    whitelist = JSON.parse((await $.get('https://raw.githubusercontent.com/antonionduarte/smart-contracts/main/abi/whitelist.json'))); 
  	abi = JSON.parse((await $.get('https://raw.githubusercontent.com/antonionduarte/smart-contracts/main/abi/MoneyBags.json'))); // contract ABI from github as well
  
    provider = new ethers.providers.Web3Provider(window.ethereum)
    await provider.send("eth_requestAccounts", [])
    signer = provider.getSigner();
    
    contract = new ethers.Contract(contractAddress, abi.output.abi, signer);
  }
  
  const mintToken = async () => {
    var select = document.getElementById("field");
    var selectedValue = select.options[select.selectedIndex].value
    console.log(selectedValue);
    console.log("mint-button");
    const valueStr = (0.1 * selectedValue).toString()

    const addr = await signer.getAddress()
    const addrStr = addr.toString("hex")
    const key = getKey(addrStr)
    
    console.log(key)
    const coupon = desserializeKey(key)
    
    const result = await contract.mint(signer.getAddress(), selectedValue, coupon, {
      value: ethers.utils.parseEther(valueStr)
    })

    await result.wait()
    setTokenBalance()
	}
  
  const getKey = (addrStr) => {
    let users = whitelist.users

    for (var i in users) {
      if ((users[i].address).toUpperCase() === (addrStr).toUpperCase()) {
        return users[i].key
      }
    }

		return users[0].key 
	}

  function desserializeKey(key) {
    let divided_key = key.split("-");

    return {
      r: "0x" + divided_key[0],
      s: "0x" + divided_key[1],
      v: parseInt(divided_key[2])
    }
  }
  
  async function eventListeners() {
    //document.getElementById("balance-button").addEventListener('click', setBalance);
    document.getElementById("mint-button").addEventListener('click', mintFrontend)
    //document.getElementById("token-balance-button").addEventListener('click', setTokenBalance);
    //document.getElementById("mint-quantity-slider").oninput = () => {
      //quantityToMint = mint_quantity_slider.value
      //document.getElementById("quantity-to-mint").innerHTML = quantityToMint
    //}
  }
  
  async function mintFrontend() {
    await mintToken()
  }

  main();
	eventListeners();

</script>