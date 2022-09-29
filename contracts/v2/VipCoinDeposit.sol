// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "hardhat/console.sol";
import "./AppCore.sol";
import "./Roles.sol";

abstract contract VipCoinDeposit is IVipCoinDeposit, AppCore, ReentrancyGuard {

    event Deposit(address indexed operator, address indexed receiver, uint256 indexed tokenId, uint256 amount);

    uint256 public constant TOKEN_ID_AIRDROP = 1;

    IAppRegistry public appRegistry;

    function __VipCoinDeposit_init(address owner, IAppRegistry appRegistry_) internal onlyInitializing {
        _setupRole(Roles.AIRDROP_ROLE, owner);

        appRegistry = appRegistry_;
    }

    /**
     * @dev Returns the amount of VIP coins owned by `account`.
     *
     * The 1st amount is from user deposit, and the 2nd amount is from airdrop.
     */
    function balanceOf(address account) public view override returns (uint256, uint256) {
        uint256 coins = vipCoin.balanceOf(account, TOKEN_ID_COIN);
        uint256 airdrops = vipCoin.balanceOf(account, TOKEN_ID_AIRDROP);
        return (coins, airdrops);
    }

    /**
     * @dev Deposits `amount` of VIP coins for `receiver`.
     */
    function deposit(uint256 amount, address receiver) public override nonReentrant {
//        console.log("amount: %s , receiver %s", amount, receiver);
        SafeERC20.safeTransferFrom(appCoin, _msgSender(), address(this), amount);
        vipCoin.mint(receiver, TOKEN_ID_COIN, amount, "");
        emit Deposit(_msgSender(), receiver, TOKEN_ID_COIN, amount);

        appRegistry.addUser(receiver);
    }

    /**
     * @dev Deposits `amount` of asset coins for `receiver`.
     */
    function depositAsset(uint256 amount, address receiver) public nonReentrant {
        // user should approve to this first
        uint256 assets = appCoin.previewMint(amount);
        SafeERC20.safeTransferFrom(IERC20(appCoin.asset()), _msgSender(), address(this), assets);
        SafeERC20.safeApprove(IERC20(appCoin.asset()), address(appCoin), assets);
        appCoin.deposit(assets, address(this));

        vipCoin.mint(receiver, TOKEN_ID_COIN, amount, "");
        emit Deposit(_msgSender(), receiver, TOKEN_ID_COIN, amount);

        appRegistry.addUser(receiver);
    }

    /**
     * @dev Air drops `amount` of VIP coins for `receiver`.
     */
    function airdrop(address receiver, uint256 amount) public nonReentrant onlyRole(Roles.AIRDROP_ROLE) {
        vipCoin.mint(receiver, TOKEN_ID_AIRDROP, amount, "");
        emit Deposit(_msgSender(), receiver, TOKEN_ID_AIRDROP, amount);

        appRegistry.addUser(receiver);
    }

    /**
     * @dev Supports airdrop in batch.
     */
    function airdropBatch(
        address[] memory receivers,
        uint256[] memory amounts,
        string[] memory reasons
    ) public nonReentrant onlyRole(Roles.AIRDROP_ROLE) {
        require(
            receivers.length == amounts.length && receivers.length == reasons.length,
            "App: length mismatch for parameters"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            vipCoin.mint(receivers[i], TOKEN_ID_AIRDROP, amounts[i], "");
            emit Deposit(_msgSender(), receivers[i], TOKEN_ID_AIRDROP, amounts[i]);

            appRegistry.addUser(receivers[i]);
        }
    }

}
