## `App`



App represents an application to provide API or functionality service.


### `initialize(contract AppCoinV2 appCoin_, contract IVipCoin vipCoin_, contract ApiWeightToken apiWeightToken_, uint256 deferTimeSecs_, address owner, contract IAppRegistry appRegitry_)` (public)



For initialization in proxy constructor.

### `chargeBatch(struct IAppConfig.ChargeRequest[] requestArray)` (public)

Billing service calls it to charge for api cost.



### `charge(address account, uint256 amount, bytes, struct IAppConfig.ResourceUseDetail[] useDetail)` (internal)

charge, consume airdrop first, then real quota.



### `_charge(address account, uint256 amount, bytes, struct IAppConfig.ResourceUseDetail[] useDetail)` (internal)








