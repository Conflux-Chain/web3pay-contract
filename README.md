# web3pay-contract
Smart contracts for Web3 payment service.

Quick start:

```shell 
yarn install
ts-node scripts/setupERC777.ts
yarn compile
yarn test-api-coin
```

Deploy:

create .env file with these variables configured:
- TEST_RPC_URL: blockchain rpc endpoint.
- PRIVATE_KEY: account to deploy.

run 
```shell
# generate files needed when verifying contract on scan
./scripts/flatten.sh  
yarn test-deploy
```

Make sure account has enough balance.