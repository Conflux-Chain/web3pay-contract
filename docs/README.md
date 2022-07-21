
## Payment Workflow
0. Admin deploys API Coin Contract, sets its `baseToken`.
1. Provider creates an app through `Controller`.
2. Consumer deposits native value or erc20 token to `API Coin Contract`.
3. `API Coin Contract` swaps these tokens to `baseToken` if needed, 
    and keeps these real asset, mints API coins for consumer.
4. `API Coin Contract` sends API coins from consumer to the app contract.
5. `App Contract` mints same amount of `App coin` to consumer. 
6. Consumer gets API key and makes some requests to Provider's service.

## Table of functions

|Role|  Function   | Doc  |
|  ----|  ----  | ----  |
| Provider|    |   |
| | Create App  | [Controller](Controller.md) |
| | Config/Query Resource  | [AppConfig](AppConfig.md) |
| | Query Apps Created by someone  | [Controller](Controller.md) |
| | Airdrop  | [Airdrop](Airdrop.md) |
| Consumer|    |   |
| | Query All App  | [Controller](Controller.md) |
| | Query Apps someone had paid  | [ApiCoin](APICoin.md) |
| | Deposit  | [ApiCoin](APICoin.md) [TokenRouter](TokenRouter.md) |
| | withdraw (Api Coin) | [TokenRouter](TokenRouter.md) |
| | Withdraw Request (App Coin) | [AppCoin](APPCoin.md) |
| | Force Withdraw (App Coin) | [AppCoin](APPCoin.md) |
| Admin|    |   |
| | charge  | [AppCoin](APPCoin.md) [Airdrop](Airdrop.md) |
| | balanceOf  | [AppCoin](APPCoin.md) |
| | balanceOfWithAirdrop  | [Airdrop](Airdrop.md) |

## Contract docs

|  Contract   | Description  | Main Functions |
|  ----  | ----  | ---- |
|  [Controller.sol](Controller.md)  | Control creation of apps  | createApp, listAppByCreator, listApp |
|  -  |   |  |
|[TokenRouter.sol](TokenRouter.md)| Deposit Bridge of API Coin|depositNativeValue, depositBaseToken, depositWithSwap, withdraw|
|[ApiCoin.sol](APICoin.md) |API Coin, funds gateway|listPaidApp, methods inherited from AirDrop and TokenRouter|
|  -  |   |  |
|[AppConfig.sol](AppConfig.md)|Manage configuration of apps, part of AppCoin|configResource, configResourceBatch, listResources|
|  [Airdrop.sol](Airdrop.md)  | Airdrop part of APP Coin  | airdrop, airdropBatch, balanceOfWithAirdrop |
|[AppCoin.sol](APPCoin.md)|Settlement contract for apps|charge, chargeBatch, freeze, withdrawRequest, forceWithdraw, takeProfit, setForceWithdrawDelay, listUser, methods inherited from AppConfig and Airdrop.|

