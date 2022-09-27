## `VipCoinWithdraw`






### `__VipCoinWithdraw_init(uint256 deferTimeSecs_, address owner)` (internal)





### `withdraw(address account, bool toAssets)` (public)



Withdraw all VIP coins by approved account.

Generally, there are two scenarios:
1. Once force withdraw requested and settlement completed, approved account
could help user to withdraw timely.
2. API provider desires to do so.

### `requestForceWithdraw()` (public)



Allow users to submit request to force withdraw VIP coins.

### `forceWithdraw(address receiver, bool toAssets)` (public)



Force withdraw all VIP coins deposited by user self.

Parameters:
- receiver: to receive the APP coins or assets.
- toAssets: receive assets instead of APP coins.

### `forceWithdrawEth(address receiver, contract IWithdrawHook hook, uint256 ethMin)` (public)






### `Frozen(address account)`





### `Withdraw(address operator, address account, address receiver, uint256 amount)`







