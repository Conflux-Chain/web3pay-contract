## `ApiWeightToken`

Config api weights and display as 1155 NFT.




### `constructor(contract IApp belongsTo, string name, string symbol, string uri)` (public)





### `initialize(contract IApp belongsTo, string name, string symbol, string uri, uint256 defaultWeight)` (public)





### `addRequestTimes(address account, struct IAppConfig.ResourceUseDetail[] useDetail)` (external)





### `setPendingSeconds(uint256 seconds_)` (public)

In order to facilitate debugging, a delayed effective time interval can be set.
It is required that the asset token is an address on testnet.



### `_mintConfig(address to, uint256 id, uint256 amount, bytes data)` (internal)





### `_burnConfig(address from, uint256 id, uint256 amount)` (internal)





### `_beforeTokenTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data)` (internal)





### `supportsInterface(bytes4 interfaceId) → bool` (public)





### `_authorizeAppConfig()` (internal)








