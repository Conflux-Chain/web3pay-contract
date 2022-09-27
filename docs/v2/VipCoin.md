## `VipCoin`



VipCoin represents application managed coins for user to consume.

ERC1155 standard allow applications to define multiple kinds of coins for users.

On the other hand, unlike a standard ERC1155 token, users could not transfer
tokens. Instead, it's up to privileged operator to mint, transfer or burn tokens.


### `constructor(string name, string symbol, string uri)` (public)





### `burn(address account, uint256 id, uint256 value)` (public)





### `burnBatch(address account, uint256[] ids, uint256[] values)` (public)





### `_beforeTokenTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data)` (internal)





### `supportsInterface(bytes4 interfaceId) → bool` (public)








