// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VipCoin.sol";

/**
 * @dev App represents an application to provide API or functionality service.
 */
contract App is AccessControlEnumerable, ReentrancyGuard {

    uint256 private constant TOKEN_ID_COIN = 0;
    uint256 private constant TOKEN_ID_AIRDROP = 1;

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    IERC20 public appCoin;
    VipCoin public vipCoin;

    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(IERC20 appCoin_, VipCoin vipCoin_) public {
        require(address(appCoin) == address(0), "App: already initialized");

        appCoin = appCoin_;
        vipCoin = vipCoin_;
    }

    /**
     * @dev Returns the amount of VIP coins owned by `account`.
     *
     * The 1st amount is from user deposit, and the 2nd amount is from airdrop.
     */
    function balanceOf(address account) public view returns (uint256, uint256) {
        uint256 coins = vipCoin.balanceOf(account, TOKEN_ID_COIN);
        uint256 airdrops = vipCoin.balanceOf(account, TOKEN_ID_AIRDROP);
        return (coins, airdrops);
    }

    /**
     * @dev Deposits `amount` of VIP coins for `receiver`.
     */
    function deposit(uint256 amount, address receiver) public nonReentrant {
        SafeERC20.safeTransferFrom(appCoin, _msgSender(), address(this), amount);
        vipCoin.mint(receiver, TOKEN_ID_COIN, amount, "");
    }

    /**
     * @dev Air drops `amount` of VIP coins for `receiver`.
     */
    function airdrop(address receiver, uint256 amount) public nonReentrant onlyRole(AIRDROP_ROLE) {
        vipCoin.mint(receiver, TOKEN_ID_AIRDROP, amount, "");
    }

    /**
     * @dev Supports airdrop in batch.
     */
    function airdropBatch(
        address[] memory receivers,
        uint256[] memory amounts,
        string[] memory reasons
    ) public nonReentrant onlyRole(AIRDROP_ROLE) {
        require(
            receivers.length == amounts.length && receivers.length == reasons.length,
            "App: length mismatch for parameters"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            vipCoin.mint(receivers[i], TOKEN_ID_AIRDROP, amounts[i], "");
        }
    }

    // TODO allow user to force withdraw coins from deposit.

    // TODO allow user to use CFX for deposit/withdrawal based on swap.

    // TODO integrate API weight contract to consume VIP coins.

    // TODO integrate VIP card in advance.

}
