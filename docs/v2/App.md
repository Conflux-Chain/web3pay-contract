## `App`



App represents an application to provide API or functionality service.


### `initialize(contract AppCoinV2 appCoin_, contract IVipCoin vipCoin_, address apiWeightToken_, uint256 deferTimeSecs_, address owner, contract IAppRegistry appRegistry_)` (public)



For initialization in proxy constructor.

### `setProps(address cardShop_, string link_, string description_, enum IApp.PaymentType paymentType_)` (public)





### `takeProfit(address to, uint256 amount)` (public)





### `chargeBatch(struct IAppConfig.ChargeRequest[] requestArray)` (public)

Billing service calls it to charge for api cost.



### `charge(address account, uint256 amount, bytes, struct IAppConfig.ResourceUseDetail[] useDetail)` (internal)

charge, consume airdrop first, then real quota.



### `_charge(address account, uint256 amount, bytes, struct IAppConfig.ResourceUseDetail[] useDetail)` (internal)





### `makeCard(address to, uint256 tokenId, uint256 amount)` (external)








