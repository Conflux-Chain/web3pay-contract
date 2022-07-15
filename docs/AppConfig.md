## `AppConfig`






### `constructor()` (internal)





### `_authorizeAppConfig()` (internal)





### `configResourceBatch(struct AppConfig.ConfigRequest[] entries)` (public)





### `configResource(struct AppConfig.ConfigRequest entry)` (public)





### `_configResource(struct AppConfig.ConfigRequest entry)` (internal)





### `listResources(uint256 offset, uint256 limit) → struct AppConfig.ConfigEntry[], uint256 total` (public)






### `ResourceChanged(uint32 id, uint32 weight, enum AppConfig.OP op)`






### `ConfigEntry`


string resourceId


uint32 weight


uint32 index


### `ConfigRequest`


uint32 id


string resourceId


uint32 weight


enum AppConfig.OP op



### `OP`











