## `VipCoinDeposit`






### `__VipCoinDeposit_init(address owner, contract AppRegistry appRegistry_)` (internal)





### `balanceOf(address account) → uint256, uint256` (public)



Returns the amount of VIP coins owned by `account`.

The 1st amount is from user deposit, and the 2nd amount is from airdrop.

### `deposit(uint256 amount, address receiver)` (public)



Deposits `amount` of VIP coins for `receiver`.

### `depositAsset(uint256 amount, address receiver)` (public)



Deposits `amount` of asset coins for `receiver`.

### `airdrop(address receiver, uint256 amount)` (public)



Air drops `amount` of VIP coins for `receiver`.

### `airdropBatch(address[] receivers, uint256[] amounts, string[] reasons)` (public)



Supports airdrop in batch.


### `Deposit(address operator, address receiver, uint256 tokenId, uint256 amount)`







