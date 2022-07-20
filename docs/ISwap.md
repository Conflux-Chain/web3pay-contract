## `ISwap`

The interface of swapping contract (SwappiRouter on Conflux eSpace).




### `swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) → uint256[] amounts` (external)





### `swapETHForExactTokens(uint256 amountOut, address[] path, address to, uint256 deadline) → uint256[] amounts` (external)

An important difference here: the cost of native value will be dynamically calculated through function `getAmountsIn`.
Exceeded value will be send back to the caller.



### `getAmountsIn(uint256 amountOut, address[] path) → uint256[] amounts` (external)








