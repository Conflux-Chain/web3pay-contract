# web3pay-contract
Smart contracts for Web3 payment service.

[Contract Docs](./docs/v2/v2.md)

Quick start:

```shell 
yarn install
yarn compile
```

Deploy:

create .env file with these variables configured:
- TEST_SCAN_URL: scan url for contract verifying.
- TEST_RPC_URL: blockchain rpc endpoint.
- PRIVATE_KEY: deployer's private key.

run 
```shell
# generate files needed when verifying contract on scan
./scripts/flatten-v2.sh
yarn test-deploy-v2
```

Make sure deployer account has enough balance.
