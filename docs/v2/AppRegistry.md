## `AppRegistry`



AppRegistry is used to manage all registered applications.


### `initialize(contract AppFactory appFactory_, contract ISwapExchange exchanger_)` (public)





### `setExchanger(contract ISwapExchange exchanger_)` (public)





### `setCreatorRoleDisabled(bool disabled)` (public)





### `getExchanger() → contract ISwapExchange` (external)





### `create(string name, string symbol, string link, string description, enum IApp.PaymentType paymentType_, uint256 deferTimeSecs, uint256 defaultApiWeight, address owner) → address` (public)



Creates a new application via configured factory.

### `remove(address app)` (public)



Removes specified `app` by owner.

### `addUser(address user) → bool` (public)





### `get(address app) → struct AppRegistry.AppInfo` (public)





### `get(address owner, address app) → struct AppRegistry.AppInfo` (public)





### `list(uint256 offset, uint256 limit) → uint256, struct AppRegistry.AppInfo[]` (public)





### `listByOwner(address owner, uint256 offset, uint256 limit) → uint256, struct AppRegistry.AppInfo[]` (public)





### `listByUser(address user, uint256 offset, uint256 limit) → uint256, struct AppRegistry.AppInfo[]` (public)






### `Created(address app, address operator, address owner, address apiWeightToken, address vipCoin)`





### `Removed(address app, address operator)`






### `AppInfo`


address addr


uint256 createTime



