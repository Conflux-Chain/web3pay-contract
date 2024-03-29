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

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
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
    function WETH() external view returns (address);
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
    address public swap_;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
    constructor() {
    }
    /** Set baseToken. Cannot put it in constructor because subcontract may be proxyable. */
    function initTokenRouter(address baseToken_) public {
        require(baseToken == address(0), 'already initialized');
        baseToken = baseToken_;
    }
    /** subcontract overrides it and checks permission. */
    function setSwap(address _swap) public virtual {
        require(swap_ == address(0), "already set");
        swap_ = _swap;
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
    function depositNativeValue(address swap, uint amountOut, address[] memory path, address toApp, uint deadline) public payable {
        require(path[path.length-1] == baseToken, 'invalid path');
        uint balance0 = IERC20(baseToken).balanceOf(address(this));

        // get exact cost
        uint[] memory amountsIn = ISwap(swap).getAmountsIn(amountOut, path);
        require(msg.value >= amountsIn[0], "insufficient payment");
        // send exact cost to swap
        uint[] memory amounts = ISwap(swap).swapETHForExactTokens{value: amountsIn[0]}(amountOut, path, address(this), deadline);
        _checkSwapResultAndMint(amounts, balance0, toApp);
        uint dust = msg.value - amountsIn[0];
        if (dust > 0) {
            safeTransferETH(msg.sender, dust);
        }
    }
    /** adjust quote token, if it was zero, use WETH. */
    function checkPayToken(address pay) internal view returns (address, bool isWETH) {
        if (pay == address(0)) {
            return (ISwap(swap_).WETH(), true);
        }
        return (pay,false);
    }
    /** build an address[] memory as path */
    function buildPath(address t1, address t2) internal pure returns (address[] memory path){
        path = new address[](2);
        path[0] = t1;
        path[1] = t2;
    }
    /**
     * calculate how much `pay` token is needed when swapping for amountOut baseToken,
     * using zero address as `pay` indicates using native value.
     */
    function getAmountsIn(address pay, uint amountOut) public view returns (uint) {
        (pay, ) = checkPayToken(pay);
        uint[] memory amountsIn = ISwap(swap_).getAmountsIn(amountOut, buildPath(pay, baseToken));
        return amountsIn[0];
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
    /** deposit without caring about the underlying swapping detail,
     * use zero address as `pay` when paying native value.
     */
    function depositWrap(address pay, // pay which token, address(0) means native value
        uint amountIn,
        uint amountOutMin,
        address toApp, uint deadline
            ) public payable {
        bool isWETH;
        (pay, isWETH) = checkPayToken(pay);
        if (isWETH) {
            depositNativeValue(swap_, amountOutMin, buildPath(pay, baseToken), toApp, deadline);
        } else {
            require(msg.value == 0, "unused payment");
            depositWithSwap(swap_, amountIn, amountOutMin, buildPath(pay, baseToken), toApp, deadline);
        }
    }
    /** Deposit other token rather than base token, do an auto swapping. Must do approving first. */
    function depositWithSwap(address swap,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
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
    /** swapTokensForExactBaseTokens, call swap.swapTokensForExactTokens() */
    function swapTokensForExactBaseTokens(address swap,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address toApp,
        uint deadline) public {
        uint balance0 = IERC20(baseToken).balanceOf(address(this));

        // swapping should end with baseToken
        require(path[path.length-1] == baseToken, 'invalid path');

        uint[] memory amountsIn = ISwap(swap).getAmountsIn(amountOut, path);
        require(amountsIn[0] <= amountInMax, 'TokenRouter: EXCESSIVE_INPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountsIn[0]);
        IERC20(path[0]).approve(swap, amountsIn[0]);
        uint[] memory amounts = ISwap(swap).swapTokensForExactTokens(amountOut, amountsIn[0], path, address(this), deadline);
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
        if (path[1] == ISwap(swap).WETH()) {
            ISwap(swap).swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        } else {
            ISwap(swap).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        }
    }

    /** Subclass should implement this method. */
    function _burnInner(uint /*amount*/, bytes memory /*data*/) internal virtual {
        // method stub
    }
}