// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** The interface of swapping contract (SwappiRouter on Conflux eSpace). */
interface ISwap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * An important difference here: the cost of native value will be dynamically calculated through function `getAmountsIn`.
     * Exceeded value will be send back to the caller.
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
 * Usage of this contract: supporting depositing kinds of ERC20 tokens.
 * It could be initialized with a `baseToken`, also called anchor token, pricing token.
 * User could deposit `baseToken` directly, or, deposit other tokens , there will be a automatically `swapping`.
 * Both way need `approve` token to this contract first.
 */
contract TokenRouter {
    /** Token used for pricing. */
    address public baseToken;
    constructor() {
    }
    /** Set baseToken. Cannot put it in constructor because subcontract may be proxyable. */
    function initTokenRouter(address baseToken_) public {
        require(baseToken == address(0), 'already initialized');
        baseToken = baseToken_;
    }
    /**
     * Deposit native value, that is CFX on conflux chain.
     * When depositing from Conflux Core space, the value sent should equal to amount needed by the swapping,
     * otherwise left value will stay at the mapped account in eSpace, and can be withdraw through CrossSpaceCall.
     *
     * Parameters:
     * - swap: Swapping contract address
     * - amountOut: Desired amount of `baseToken`
     * - path: Swapping path used by swapping contract. Generally, it's the address of [WCFX, baseToken]
     * - toApp: deposit for which app
     * - deadline: timestamp ( in seconds ) before which this transaction should be executed.
     */
    function depositNativeValue(address swap, uint amountOut, address[] calldata path, address toApp, uint deadline) public payable {
        require(path[path.length-1] == baseToken, 'invalid path');
        uint balance0 = IERC20(baseToken).balanceOf(address(this));

        // get exact cost
        uint[] memory amountsIn = ISwap(swap).getAmountsIn(amountOut, path);
        // send exact cost to swap
        uint[] memory amounts = ISwap(swap).swapETHForExactTokens{value: amountsIn[0]}(amountOut, path, address(this), deadline);
        _checkSwapResultAndMint(amounts, balance0, toApp);
        uint dust = msg.value - amountsIn[0];
        if (dust > 0) {
            safeTransferETH(msg.sender, dust);
        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /** Deposit base token directly. Must do approving first. */
    function depositBaseToken(uint amountIn, address toApp) public {
        //must approve to this first
        IERC20(baseToken).transferFrom(msg.sender, address(this), amountIn);
        _mintAndSend(amountIn, toApp);
    }

    /** Deposit other token rather than base token, do an auto swapping. Must do approving first. */
    function depositWithSwap(address swap,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address toApp,
        uint deadline) public {
        uint balance0 = IERC20(baseToken).balanceOf(address(this));

        // swapping should end with baseToken
        require(path[path.length-1] == baseToken, 'invalid path');
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(swap, amountIn);
        uint[] memory amounts = ISwap(swap).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        _checkSwapResultAndMint(amounts, balance0, toApp);
    }

    /** Make sure this contract receives exact amount of baseToken,
     *  and then mint that amount of token represented by this contract,
     *  and then send minted tokens from msg.sender to toApp.
     */
    function _checkSwapResultAndMint(uint[] memory amounts, uint balance0, address toApp) internal {
        uint swapGain = amounts[amounts.length - 1];
        // check balance diff
        uint actualGain = IERC20(baseToken).balanceOf(address(this)) - balance0;
        require(actualGain == swapGain, string(abi.encodePacked("swap value mismatch", actualGain, swapGain)));
        // call API Coin deposit/_mint();
        _mintAndSend(actualGain, toApp);
    }

    /** Subclass should implement this method. */
    function _mintAndSend(uint amount, address appCoin) internal virtual {
        // method stub
    }

    /**
     * Withdraw baseToken or other token, depends on the path passed in.
     *
     * Parameters:
     * - swap: Swapping contract address
     * - amountIn: amount of baseToken
     * - amountOutMin: minimum amount of wanted output token
     * - path: swapping path, could be [baseToken] or [baseToken, wantedToken]
     * - to: who will receive the output tokens
     * - deadline: timestamp ( in seconds ) before which this transaction should be executed.
     */
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

    /** Subclass should implement this method. */
    function _burnInner(uint /*amount*/, bytes memory /*data*/) internal virtual {
        // method stub
    }
}