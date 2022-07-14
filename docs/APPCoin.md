## `APPCoin`



Settlement contract between API consumer and API supplier.

For Api supplier:
- setResourceWeightBatch
- setResourceWeight
- charge
- freeze
- takeProfit

For api consumer:
- withdrawRequest
- forceWithdraw
- freeze

### `onlyAppOwner()`






### `tokensReceived(address, address from, address, uint256 amount, bytes, bytes)` (external)





### `_beforeTokenTransfer(address operator, address from, address to, uint256 amount)` (internal)





### `freeze(address acc, bool f)` (public)



Freeze/Unfreeze an account.

### `takeProfit(address to, uint256 amount)` (public)





### `charge(address account, uint256 amount, bytes data)` (public)



Charge fee

### `burn(uint256 amount, bytes)` (public)

Prevent anyone from transferring app coin.

Not permitted.


### `withdrawRequest()` (public)



Used by an API consumer to send a withdraw request, API key related to the caller will be frozen.

### `forceWithdraw()` (public)



After some time, user can force withdraw his funds anyway.

### `setForceWithdrawAfterBlock(uint256 diff)` (public)





### `initOwner(address owner_)` (public)

 Called immediately after constructing through Controller contract.



### `init(address apiCoin_, address appOwner_, string name_, string symbol_)` (public)





### `pause()` (public)





### `unpause()` (public)





### `_authorizeAppConfig()` (internal)





### `balanceOfWithAirdrop(address owner) → uint256 total, uint256 airdrop` (public)






### `Frozen(address addr)`





### `Withdraw(address account, uint256 amount)`







