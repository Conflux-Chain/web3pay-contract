// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AppCore.sol";

abstract contract VipCoinDeposit is AppCore, ReentrancyGuard {

    event Deposit(address indexed operator, address indexed receiver, uint256 indexed tokenId, uint256 amount);

    uint256 public constant TOKEN_ID_AIRDROP = 1;

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    function __VipCoinDeposit_init(address owner) internal onlyInitializing {
        _setupRole(AIRDROP_ROLE, owner);
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
        emit Deposit(_msgSender(), receiver, TOKEN_ID_COIN, amount);
    }

    /**
     * @dev Air drops `amount` of VIP coins for `receiver`.
     */
    function airdrop(address receiver, uint256 amount) public nonReentrant onlyRole(AIRDROP_ROLE) {
        vipCoin.mint(receiver, TOKEN_ID_AIRDROP, amount, "");
        emit Deposit(_msgSender(), receiver, TOKEN_ID_AIRDROP, amount);
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
            emit Deposit(_msgSender(), receivers[i], TOKEN_ID_AIRDROP, amounts[i]);
        }
    }

}
