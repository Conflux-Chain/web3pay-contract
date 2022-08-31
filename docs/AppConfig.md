## `AppConfig`

Configuration functions for an App.




### `constructor()` (internal)





### `_authorizeAppConfig()` (internal)





### `configResourceBatch(struct AppConfig.ConfigRequest[] entries)` (public)





### `configResource(struct AppConfig.ConfigRequest entry)` (public)

There is a delayed execution mechanism when configuring resources.



### `_configResource(struct AppConfig.ConfigRequest entry)` (internal)





### `setPendingProp(uint32 id, enum AppConfig.OP op_, uint256 weight_)` (internal)





### `flushPendingConfig()` (public)

Make the configuration that satisfies the delay mechanism take effect.



### `_flushPendingConfig(uint256 pendingSeconds_)` (internal)





### `listUserRequestCounter(address user, uint32[] ids) → uint256[] times` (public)





### `listResources(uint256 offset, uint256 limit) → struct AppConfig.ConfigEntry[], uint256 total` (public)





### `_mintConfig(address to, uint256 id, uint256 amount, bytes data)` (internal)





### `_burnConfig(address from, uint256 id, uint256 amount)` (internal)






### `ResourceChanged(uint32 id, uint256 weight, enum AppConfig.OP op)`





### `ResourcePending(uint32 id, uint256 newWeight, enum AppConfig.OP op)`






### `ConfigEntry`


string resourceId


uint256 weight


uint32 index


enum AppConfig.OP pendingOP


uint256 pendingWeight


uint256 submitSeconds


uint256 requestTimes


### `ConfigRequest`


uint32 id


string resourceId


uint256 weight


enum AppConfig.OP op



### `OP`

















