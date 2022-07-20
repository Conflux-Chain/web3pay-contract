## `TokenRouter`

Usage of this contract: supporting depositing kinds of ERC20 tokens.
It could be initialized with a `baseToken`, also called anchor token, pricing token.
User could deposit `baseToken` directly, or, deposit other tokens , there will be a automatically `swapping`.
Both way need `approve` token to this contract first.




### `initTokenRouter(address baseToken_)` (public)

Set baseToken. Cannot put it in constructor because subcontract may be proxyable.



### `depositNativeValue(address swap, uint256 amountOut, address[] path, address toApp, uint256 deadline)` (public)

Deposit native value, that is CFX on conflux chain.
When depositing from Conflux Core space, the value sent must equal to amount needed by the swapping,
otherwise the transaction will fail, because left value can not be send back.

Parameters:
- swap: Swapping contract address
- amountOut: Desired amount of `baseToken`
- path: Swapping path used by swapping contract. Generally, it's the address of [WCFX, baseToken]
- toApp: deposit for which app
- deadline: timestamp ( in seconds ) before which this transaction should be executed.



### `depositBaseToken(uint256 amountIn, address toApp)` (public)

Deposit base token directly. Must do approving first.



### `depositWithSwap(address swap, uint256 amountIn, uint256 amountOutMin, address[] path, address toApp, uint256 deadline)` (public)

Deposit other token rather than base token, do an auto swapping. Must do approving first.



### `_checkSwapResultAndMint(uint256[] amounts, uint256 balance0, address toApp)` (internal)

Make sure this contract receives exact amount of baseToken,
 and then mint that amount of token represented by this contract,
 and then send minted tokens from msg.sender to toApp.



### `_mintAndSend(uint256 amount, address appCoin)` (internal)

Subclass should implement this method.



### `withdraw(address swap, uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline)` (public)

Withdraw baseToken or other token, depends on the path passed in.

Parameters:
- swap: Swapping contract address
- amountIn: amount of baseToken
- amountOutMin: minimum amount of wanted output token
- path: swapping path, could be [baseToken] or [baseToken, wantedToken]
- to: who will receive the output tokens
- deadline: timestamp ( in seconds ) before which this transaction should be executed.



### `_burnInner(uint256, bytes)` (internal)

Subclass should implement this method.






