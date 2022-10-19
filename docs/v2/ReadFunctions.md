## `ReadFunctions`

Helper functions for reading.




### `initialize(contract IAppRegistry reg_)` (public)





### `getUserAppInfo(address user, address app) → struct ReadFunctions.UserApp userApp` (public)





### `listAppByUser(address user, uint256 offset, uint256 limit) → uint256 total, struct ReadFunctions.UserApp[] apps` (public)







### `UserApp`


address app


string name


string symbol


string link


enum IApp.PaymentType paymentType_


string vipCardName


uint256 vipExpireAt


uint256 balance


uint256 airdrop



