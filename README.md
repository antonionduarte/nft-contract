# smart contract development

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

- Test Public Key: 0x402a4189b1d72EdFBc9dfEb7771e4A5549B43531
- Test Private Key: 082c2e79e6b92eb1ae329fcd9eeebc7c6605e0f20269e54123104da270d10419

# deploy to localhost

Run the following command:
```npx hardhat run scripts/localhost-script.js --network localhost```

# notes

- In a final deployment contract I might want to hardcode quite a lot of variables and functions like:
- changeAdminSigner()
- contractChain()
- changeNumberTokens()
- contractBalance()