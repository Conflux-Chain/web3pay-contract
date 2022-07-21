## `Airdrop`

Use this contract to airdrop to user with some free quota.
When charging, airdrops are consumed prior to real deposited quota.




### `airdrop(address to, uint256 amount, string reason)` (public)

AppOwner could airdrop to user.



### `airdropBatch(address[] to, uint256[] amount, string[] reason)` (public)





### `balanceOfWithAirdrop(address owner) → uint256 total, uint256 airdrop_` (public)

Query user's balance, returns (total amount, airdrop amount)



### `charge(address account, uint256 amount, bytes data)` (public)

Charge account's quota.
Will emit `Spend` event if airdrops are consumed.
Will always emit ERC20 `Transfer` event (even real quota consumed is zero).




### `Spend(address from, uint256 amount)`





### `Drop(address to, uint256 amount, string reason)`







