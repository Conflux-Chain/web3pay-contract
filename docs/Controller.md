## `Controller`



DApp developers can register their app through this controller.
An ERC777 contract will be deployed, which then will be used as a settlement contract between API consumer and API supplier.


### `createApp(string name_, string symbol_)` (public)



Create/register a DApp.
An ERC777 contract will be deployed, which then will be used as a settlement contract between API consumer and API supplier.
Caller's address will be used as the `appOwner` of the contract.

### `listApp(uint256 offset, uint256 limit) → address[], uint256 total` (public)



List created DApp settlement contracts.


### `APP_CREATED(address addr, address appOwner)`



APP_CREATED event



