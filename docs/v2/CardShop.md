## `CardShop`






### `initialize(contract IApp belongsTo_, contract ICardTemplate template_, contract ICards instance_, contract ICardTracker tracker_)` (public)





### `buyWithEth(address receiver, uint256 templateId, uint256 count)` (public)

call exchanger.previewDepositETH(totalPrice) to estimate how munch eth is needed.



### `buyWithAsset(address receiver, uint256 templateId, uint256 count)` (public)





### `giveCardBatch(address[] receiverArr, uint256[] countArr, uint256 templateId)` (public)





### `getCard(uint256 id) → struct ICards.Card` (public)





### `_callMakeCard(address to, struct ICardTemplate.Template template_, uint256 count) → uint256` (internal)






### `GAVEN_CARD(address operator, address to, uint256 cardId)`







