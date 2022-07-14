## `APICoin`



API coin is the currency in the whole payment service.

For api consumer:
- depositToApp
- refund

For api supplier:
- refund



### `depositToApp(address appCoin)` (public)



Used by API consumer to deposit for specified app.

For now it only takes CFX, and 1 CFX exchanges 1 APP Coin.

API supplier may set `price/weight` for each API, so, how many requests could be made depends on both the deposited funds and
the `price/weight` of consumed API.

Parameter `appCoin` is the settlement contract of the app, please contact API supplier to get it.

### `listPaidApp(address user_, uint256 offset, uint256 limit) → address[] apps, uint256 total` (public)





### `refund(uint256 amount)` (public)



Used by anyone who holds API coin to exchange CFX back.

### `constructor()` (public)





### `initialize(string name_, string symbol_, address[] defaultOperators)` (public)





### `pause()` (public)





### `unpause()` (public)





### `_authorizeUpgrade(address newImplementation)` (internal)








