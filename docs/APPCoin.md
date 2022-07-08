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

### `setResourceWeightBatch(uint32[] indexArr, string[] resourceIdArr, uint256[] weightArr)` (public)





### `setResourceWeight(uint32 index, string resourceId, uint256 weight)` (public)





### `setForceWithdrawAfterBlock(uint256 diff)` (public)





### `listResources(uint32 offset, uint32 limit) → struct APPCoin.WeightEntry[]` (public)





### `initOwner(address owner_)` (public)





### `init(address apiCoin_, address appOwner_, string name_, string symbol_)` (public)





### `pause()` (public)





### `unpause()` (public)






### `ResourceChanged(uint32 index)`





### `Frozen(address addr)`





### `Withdraw(address account, uint256 amount)`






### `WeightEntry`


string name


uint256 weight



