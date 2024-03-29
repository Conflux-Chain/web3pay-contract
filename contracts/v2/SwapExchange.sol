// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AppCoinV2.sol";
import "./interfaces.sol";

/** The interface of swapping contract (SwappiRouter on Conflux eSpace). */
interface ISwap {
    // ETH => Token
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);

    // Token => ETH
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);

    // Token1 => Token2
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);

    function WETH() external view returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
 * @dev SwapExchange is used to deposit/withdraw App Coins based on native tokens.
 */
contract SwapExchange is IWithdrawHook, Initializable, ReentrancyGuard {

    AppCoinV2 public appCoin;
    ISwap public swap;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(AppCoinV2 appCoin_, ISwap swap_) public initializer {
        appCoin = appCoin_;
        swap = swap_;
    }

    /**
     * @dev Preview how many ETH required to deposit `amount` of App Coins.
     *
     * Parameters:
     * - amount: amount of App Coins to deposit.
     */
    function previewDepositETH(uint256 amount) public view returns (uint256) {
        amount = appCoin.previewMint(amount);

        address[] memory path = new address[](2);
        path[0] = swap.WETH();
        path[1] = appCoin.asset();

        uint[] memory amounts = swap.getAmountsIn(amount, path);

        return amounts[0];
    }

    /**
     * @dev Deposit `amount` of App Coins to `receiver` with ETH.
     *
     * Parameters:
     * - amount: amount of App Coins to deposit.
     * - receiver: address to receive the App Coins.
     */
    function depositETH(uint256 amount, address receiver) public payable nonReentrant {
        amount = appCoin.previewMint(amount);

        _swapEthForTokens(amount);

        // approve and deposit for receiver
        SafeERC20.safeApprove(IERC20(appCoin.asset()), address(appCoin), amount);
        appCoin.deposit(amount, receiver);
    }

    /**
     * @dev Preview how many ETH will be received if withdraw `amount` of App Coins.
     *
     * Parameters:
     * - amount: amount of App Coins to withdraw.
     */
    function previewWithdrawETH(uint256 amount) public view returns (uint256) {
        amount = appCoin.previewRedeem(amount);

        address[] memory path = new address[](2);
        path[0] = appCoin.asset();
        path[1] = swap.WETH();

        uint[] memory amounts = swap.getAmountsOut(amount, path);

        return amounts[1];
    }

    /**
     * @dev Withdraw `amount` of App Coins and receive ETH to the `receiver`.
     *
     * Parameters:
     * - amount: amount of App Coins to withdraw.
     * - receiver: address to receive the ETH.
     */
    function withdrawETH(uint256 amount, uint256 ethMin, address receiver) public override nonReentrant {
        // requires user to approve AppCoin to this SwapExchange
        amount = appCoin.redeem(amount, address(this), msg.sender);

        _swapTokensForEth(amount, ethMin, receiver);
    }

    function _safeTransferETH(address to, uint value) private {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'SwapExchange: transfer ETH failed');
    }

    /**
     * @dev Deposit `amount` of to VIP coins to `receiver` with ETH.
     *
     * Parameters:
     * - amount: amount of VIP Coins to deposit.
     * - receiver: address to receive the VIP Coins.
     */
    function depositAppETH(IVipCoinDeposit app, uint256 amount, address receiver) public payable nonReentrant {
        uint256 assets = appCoin.previewMint(amount);

        _swapEthForTokens(assets);

        // approve and deposit API coin
        SafeERC20.safeApprove(IERC20(appCoin.asset()), address(appCoin), assets);
        appCoin.deposit(assets, address(this));

        // approve and deposit VIP coin for receiver
        SafeERC20.safeApprove(appCoin, address(app), amount);
        app.deposit(amount, receiver);
    }

    /**
     * @dev Required when deposit ETH and swap contract refund any dust ETH.
     */
    receive() external payable {}

    function _swapEthForTokens(uint256 amount) private {
        uint256 balanceBefore = address(this).balance - msg.value;

        address[] memory path = new address[](2);
        path[0] = swap.WETH();
        path[1] = appCoin.asset();

        // swap ETH for tokens
        swap.swapETHForExactTokens{value: msg.value}(amount, path, address(this), block.timestamp);

        // refund dust ETH if any
        uint256 dust = address(this).balance - balanceBefore;
        if (dust > 0) {
            _safeTransferETH(msg.sender, dust);
        }
    }

    function _swapTokensForEth(uint256 amount, uint256 ethMin, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = appCoin.asset();
        path[1] = swap.WETH();

        // approve and swap for receiver
        SafeERC20.safeApprove(IERC20(appCoin.asset()), address(swap), amount);
        swap.swapExactTokensForETH(amount, ethMin, path, receiver, block.timestamp);
    }

}
