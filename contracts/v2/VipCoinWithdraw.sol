// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AppCore.sol";
import "./VipCoinDeposit.sol";

abstract contract VipCoinWithdraw is AppCore {

    event Frozen(address indexed account);
    event Withdraw(address indexed operator, address account, address indexed receiver, uint256 amount);

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    uint256 public deferTimeSecs;
    mapping(address => uint256) public withdrawSchedules;

    function __VipCoinWithdraw_init(uint256 deferTimeSecs_, address owner) internal onlyInitializing {
        _setupRole(WITHDRAW_ROLE, owner);

        deferTimeSecs = deferTimeSecs_;
    }

    /**
     * @dev Withdraw all VIP coins by approved account.
     *
     * Generally, there are two scenarios:
     * 1. Once force withdraw requested and settlement completed, approved account
     * could help user to withdraw timely.
     * 2. API provider desires to do so.
     */
    function withdraw(address account, bool toAssets) public onlyRole(WITHDRAW_ROLE) {
        _withdraw(_msgSender(), account, account, toAssets);
    }

    /**
     * @dev Allow users to submit request to force withdraw VIP coins.
     */
    function requestForceWithdraw() public {
        withdrawSchedules[_msgSender()] = block.timestamp;
        emit Frozen(_msgSender());
    }

    /**
     * @dev Force withdraw all VIP coins deposited by user self.
     *
     * Parameters:
     * - receiver: to receive the APP coins or assets.
     * - toAssets: receive assets instead of APP coins.
     */
    function forceWithdraw(address receiver, bool toAssets) public {
        require(withdrawSchedules[_msgSender()] > 0, "VipCoinWithdraw: force withdraw not requested");
        require(withdrawSchedules[_msgSender()] + deferTimeSecs <= block.timestamp, "VipCoinWithdraw: time locked");

        delete withdrawSchedules[_msgSender()];

        _withdraw(_msgSender(), _msgSender(), receiver, toAssets);
    }

    function _withdraw(address operator, address account, address receiver, bool toAssets) private {
        uint256 balance = vipCoin.balanceOf(account, TOKEN_ID_COIN);
        vipCoin.burn(account, TOKEN_ID_COIN, balance);

        if (toAssets) {
            appCoin.redeem(balance, receiver, address(this));
        } else {
            SafeERC20.safeTransfer(appCoin, receiver, balance);
        }

        emit Withdraw(operator, account, receiver, balance);
    }

}
