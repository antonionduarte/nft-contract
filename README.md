# Smart Contracts

Personal development repository for smart contracts.

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

# deploy to localhost

Run the following command:
```npx hardhat run scripts/localhost-script.js --network localhost```

# notes

- In a final deployment contract I might want to hardcode quite a lot of variables and functions like:
- changeAdminSigner()
- contractChain()
- changeNumberTokens()
- contractBalance()
