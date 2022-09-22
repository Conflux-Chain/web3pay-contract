// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AppCore.sol";
import "./VipCoinDeposit.sol";
import "./VipCoinWithdraw.sol";

/**
 * @dev App represents an application to provide API or functionality service.
 */
contract App is AppCore, VipCoinDeposit, VipCoinWithdraw {

    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(IERC20 appCoin_, VipCoin vipCoin_, uint256 deferTimeSecs_) public {
        _initialize(appCoin_, vipCoin_);
        deferTimeSecs = deferTimeSecs_;
    }

    // TODO allow user to use CFX for deposit/withdrawal based on swap.

    // TODO integrate API weight contract to consume VIP coins.

    // TODO integrate VIP card in advance.

}
