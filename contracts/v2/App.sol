// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AppCore.sol";
import "./VipCoinDeposit.sol";
import "./VipCoinWithdraw.sol";
import "./AppCoinV2.sol";

/**
 * @dev App represents an application to provide API or functionality service.
 */
contract App is AppCore, VipCoinDeposit, VipCoinWithdraw {

    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(AppCoinV2 appCoin_, IVipCoin vipCoin_, ApiWeightToken apiWeightToken_, uint256 deferTimeSecs_, address owner, IAppRegistry appRegitry_) public initializer {
        __AppCore_init(appCoin_, vipCoin_, apiWeightToken_, owner);
        __VipCoinDeposit_init(owner, appRegitry_);
        __VipCoinWithdraw_init(deferTimeSecs_, owner);
    }

    // TODO integrate API weight contract to consume VIP coins.

    // TODO integrate VIP card in advance.

}
