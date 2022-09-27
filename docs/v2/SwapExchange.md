## `SwapExchange`



SwapExchange is used to deposit/withdraw App Coins based on native tokens.


### `initialize(contract AppCoinV2 appCoin_, contract ISwap swap_)` (public)



For initialization in proxy constructor.

### `previewDepositETH(uint256 amount) → uint256` (public)



Preview how many ETH required to deposit `amount` of App Coins.

Parameters:
- amount: amount of App Coins to deposit.

### `depositETH(uint256 amount, address receiver)` (public)



Deposit `amount` of App Coins to `receiver` with ETH.

Parameters:
- amount: amount of App Coins to deposit.
- receiver: address to receive the App Coins.

### `previewWithdrawETH(uint256 amount) → uint256` (public)



Preview how many ETH will be received if withdraw `amount` of App Coins.

Parameters:
- amount: amount of App Coins to withdraw.

### `withdrawETH(uint256 amount, uint256 ethMin, address receiver)` (public)



Withdraw `amount` of App Coins and receive ETH to the `receiver`.

Parameters:
- amount: amount of App Coins to withdraw.
- receiver: address to receive the ETH.

### `depositAppETH(contract App app, uint256 amount, address receiver)` (public)



Deposit `amount` of to VIP coins to `receiver` with ETH.

Parameters:
- amount: amount of VIP Coins to deposit.
- receiver: address to receive the VIP Coins.

### `withdrawEth(address receiver, uint256 ethMin)` (public)



Implements the IWithdrawHook interface.

This is to allow users to force withdraw ETH.

### `receive()` (external)



Required when deposit ETH and swap contract refund any dust ETH.




