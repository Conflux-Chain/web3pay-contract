## `APPCoin`



Settlement contract between API consumer and API supplier.

For Api provider:
- setResourceWeightBatch
- setResourceWeight
- charge
- refund
- takeProfit

For api consumer:
- withdrawRequest
- forceWithdraw

### `onlyAppOwner()`






### `tokensReceived(address, address from, address, uint256 amount, bytes, bytes)` (external)





### `_addNewUser(address addr)` (internal)





### `_beforeTokenTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data)` (internal)





### `transferAppOwner(address to, address controller)` (public)



Freeze/Unfreeze an account.

### `freeze(address acc, bool f)` (public)





### `configPrivilege(address account, bool add, uint256 id)` (external)





### `takeProfit(address to, uint256 amount)` (public)





### `chargeBatch(struct IAppConfig.ChargeRequest[] requestArray)` (public)





### `charge(address account, uint256 amount, bytes, struct IAppConfig.ResourceUseDetail[] useDetail)` (public)

Charge account's quota.
Will emit `Spend` event if airdrops are consumed.
Will always emit ERC20 `Transfer` event (even real quota consumed is zero).



### `_charge(address account, uint256 amount, bytes, struct IAppConfig.ResourceUseDetail[] useDetail)` (internal)





### `withdrawRequest()` (public)



Used by an API consumer to send a withdraw request, API key related to the caller will be frozen.

### `forceWithdraw()` (public)



After the delay time expires, the user can withdraw the remaining funds.

### `refund(address account)` (public)





### `_withdraw(address account, bytes reason)` (internal)





### `_swapApiCoin(uint256 amount, address to)` (internal)





### `setForceWithdrawDelay(uint256 delay)` (public)





### `listUser(uint256 offset, uint256 limit) → struct APPCoin.UserCharged[], uint256 total` (public)





### `initOwner(address owner_)` (public)

 Called immediately after constructing through Controller contract.



### `init(address apiCoin_, address appOwner_, string name_, string symbol_, string uri_, uint256 defaultWeight)` (public)





### `pause()` (public)





### `unpause()` (public)





### `_authorizeAppConfig()` (internal)





### `balanceOfWithAirdrop(address owner) → uint256 total, uint256 airdrop` (public)





### `supportsInterface(bytes4 interfaceId) → bool` (public)





### `onERC1155Received(address, address, uint256, uint256, bytes) → bytes4` (external)





### `onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) → bytes4` (external)





### `uri(uint256 tokenId) → string` (public)





### `decimals() → uint8` (public)





### `_mintConfig(address to, uint256 id, uint256 amount, bytes data)` (internal)





### `_burnConfig(address from, uint256 id, uint256 amount)` (internal)





### `setPendingSeconds(uint256 seconds_)` (public)

In order to facilitate debugging, a delayed effective time interval can be set.
It is required that the name of this contract is DO_NOT_DEPOSIT and the symbol is ALL_YOU_FUNDS_WILL_LOST.



### `hashCompareWithLengthCheck(string a, string b) → bool` (internal)






### `AppOwnerChanged(address to)`





### `Spend(address from, uint256 amount)`





### `Drop(address to, uint256 amount, string reason)`





### `Frozen(address addr)`





### `Withdraw(address account, uint256 amount)`






### `UserCharged`


address user


uint256 amount



