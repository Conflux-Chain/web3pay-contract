## `TokenRouter`

Usage of this contract: supporting depositing kinds of ERC20 tokens.
It could be initialized with a `baseToken`, also called anchor token, pricing token.
User could deposit `baseToken` directly, or, deposit other tokens , there will be a automatically `swapping`.
Both way need `approve` token to this contract first.




### `initTokenRouter(address baseToken_)` (public)

Set baseToken. Cannot put it in constructor because subcontract may be proxyable.



### `setSwap(address _swap)` (public)

subcontract overrides it and checks permission.



### `depositNativeValue(address swap, uint256 amountOut, address[] path, address toApp, uint256 deadline)` (public)

Deposit native value, that is CFX on conflux chain.
When depositing from Conflux Core space, the value sent should equal to amount needed by the swapping,
otherwise left value will stay at the mapped account in eSpace, and can be withdraw through CrossSpaceCall.

Parameters:
- swap: Swapping contract address
- amountOut: Desired amount of `baseToken`
- path: Swapping path used by swapping contract. Generally, it's the address of [WCFX, baseToken]
- toApp: deposit for which app
- deadline: timestamp ( in seconds ) before which this transaction should be executed.



### `checkPayToken(address pay) → address, bool isWETH` (internal)

adjust quote token, if it was zero, use WETH.



### `buildPath(address t1, address t2) → address[] path` (internal)

build an address[] memory as path



### `getAmountsIn(address pay, uint256 amountOut) → uint256` (public)

calculate how much `pay` token is needed when swapping for amountOut baseToken,
using zero address as `pay` indicates using native value.



### `safeTransferETH(address to, uint256 value)` (internal)





### `depositBaseToken(uint256 amountIn, address toApp)` (public)

Deposit base token directly. Must do approving first.



### `depositWrap(address pay, uint256 amountIn, uint256 amountOutMin, address toApp, uint256 deadline)` (public)

deposit without caring about the underlying swapping detail,
use zero address as `pay` when paying native value.



### `depositWithSwap(address swap, uint256 amountIn, uint256 amountOutMin, address[] path, address toApp, uint256 deadline)` (public)

Deposit other token rather than base token, do an auto swapping. Must do approving first.



### `swapTokensForExactBaseTokens(address swap, uint256 amountOut, uint256 amountInMax, address[] path, address toApp, uint256 deadline)` (public)

swapTokensForExactBaseTokens, call swap.swapTokensForExactTokens()



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






