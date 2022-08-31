## `Controller`



DApp developers can register their app through this controller.
An ERC777 contract will be deployed, which then will be used as a settlement contract between API consumer and API supplier.


### `constructor()` (public)





### `initialize(address api_, address appBase_)` (public)





### `changeAppOwner(address from, address to)` (external)





### `createApp(string name_, string symbol_, string description_, uint256 defaultWeight)` (public)



Create/register a DApp.
Will deploy an ERC777 contract, then use it as a settlement contract between API consumer and API supplier.
Set caller as `appOwner`.
There is a delayed execution mechanism when configuring resources. It is best to set default weights at creation time.

### `listAppByCreator(address creator_, uint32 offset, uint256 limit) → struct Controller.AppInfo[] apps, uint256 total` (public)





### `listApp(uint256 offset, uint256 limit) → address[], uint256 total` (public)



List created DApp settlement contracts.

### `_authorizeUpgrade(address newImplementation)` (internal)






### `APP_CREATED(address addr, address appOwner)`



APP_CREATED event


### `AppInfo`


address addr


uint256 blockTime



