// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
contract TokenRouter {
    /** Token used for pricing. */
    address public immutable baseToken;
    constructor(address baseToken_) {
        baseToken = baseToken_;
    }
    /** Deposit native value, that is CFX on conflux chain. */
    function depositNativeValue(address swap, uint amountOut, address[] calldata path, address toApp, uint deadline) public payable {
        require(path[path.length-1] == baseToken, 'invalid path');
        uint balance0 = IERC20(baseToken).balanceOf(address(this));

        uint[] memory amounts = ISwap(swap).swapETHForExactTokens{value: msg.value}(amountOut, path, address(this), deadline);
        _checkSwapResultAndMint(amounts, balance0, toApp);
    }
    /** Deposit base token directly. */
    function depositBaseToken(uint amountIn, address toApp) public {
        //must approve to this first
        IERC20(baseToken).transferFrom(msg.sender, address(this), amountIn);
        _mintAndSend(amountIn, toApp);
    }
    /** Deposit other token rather than base token, do an auto swapping. */
    function depositWithSwap(address swap,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address toApp,
        uint deadline) public {
        uint balance0 = IERC20(baseToken).balanceOf(address(this));

        require(path[path.length-1] == baseToken, 'invalid path');
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(swap, amountIn);
        uint[] memory amounts = ISwap(swap).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        _checkSwapResultAndMint(amounts, balance0, toApp);
    }
    function _checkSwapResultAndMint(uint[] memory amounts, uint balance0, address toApp) internal {
        uint swapGain = amounts[amounts.length - 1];
        // check balance diff
        uint actualGain = IERC20(baseToken).balanceOf(address(this)) - balance0;
        require(actualGain == swapGain, string(abi.encodePacked("swap value mismatch", actualGain, swapGain)));
        // call API Coin deposit/_mint();
        _mintAndSend(actualGain, toApp);
    }
    function _mintAndSend(uint amount, address appCoin) internal virtual {
        // method stub
    }
    function withdraw(address swap,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) public {
        require(path[0] == baseToken, "invalid path");
        _burnInner(amountIn, "swapOut");
        if (path.length == 1) {
            // withdraw base token
            IERC20(baseToken).transfer(to, amountIn);
            return;
        }

        IERC20(baseToken).approve(swap, amountIn);
        ISwap(swap).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }
    function _burnInner(uint /*amount*/, bytes memory /*data*/) internal {
        // method stub
    }
}