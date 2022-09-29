// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AppCore.sol";
import "./VipCoinDeposit.sol";
import "./VipCoinWithdraw.sol";
import "./AppCoinV2.sol";
import "./interfaces.sol";

/**
 * @dev App represents an application to provide API or functionality service.
 */
contract App is AppCore, VipCoinDeposit, VipCoinWithdraw, ICards {
    // role who can charge coin from user
    bytes32 public constant CHARGE_ROLE = keccak256("CHARGE_ROLE");
    // totalCharged fees produced by billing
    uint256 public totalCharged;
    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(AppCoinV2 appCoin_, IVipCoin vipCoin_, ApiWeightToken apiWeightToken_, uint256 deferTimeSecs_, address owner, IAppRegistry appRegitry_) public initializer {
        __AppCore_init(appCoin_, vipCoin_, apiWeightToken_, owner);
        __VipCoinDeposit_init(owner, appRegitry_);
        __VipCoinWithdraw_init(deferTimeSecs_, owner);
    }

    /** Billing service calls it to charge for api cost. */
    function chargeBatch(IAppConfig.ChargeRequest[] memory requestArray) public onlyRole(CHARGE_ROLE) {
        for(uint i=0; i<requestArray.length; i++) {
            IAppConfig.ChargeRequest memory request = requestArray[i];
            charge(request.account, request.amount, request.data, request.useDetail);
        }
    }
    /** charge, consume airdrop first, then real quota. */
    function charge(address account, uint256 amount, bytes memory /*data*/, IAppConfig.ResourceUseDetail[] memory useDetail) internal {
        // consume airdrop
        uint256 spendDrop = 0;
        uint256 spendSuper = amount;
        uint256 airdrop = vipCoin.balanceOf(account, TOKEN_ID_AIRDROP);
        if (airdrop >= amount) {
            // all amount is covered by airdrop.
            spendDrop = amount;
            spendSuper = 0;
        } else if (airdrop > 0){
            //  partial amount is covered by airdrop.
            spendDrop = airdrop;
            spendSuper = amount - airdrop;
        }

        if (spendDrop > 0) {
            vipCoin.burn(account, TOKEN_ID_AIRDROP, spendDrop);
        }
        _charge(account, spendSuper, "", useDetail);
    }
    /* charge real quota without checking billing permission. **/
    function _charge(address account, uint256 amount, bytes memory /*data*/, IAppConfig.ResourceUseDetail[] memory useDetail) internal {
        vipCoin.burn(account, TOKEN_ID_COIN, amount);
        totalCharged += amount;

        apiWeightToken.addRequestTimes(account, useDetail);

        if (withdrawSchedules[account] > 1) {
            // refund
            _withdraw(msg.sender, account, account, true);
        }
    }

    function makeCard(address to, Card memory card, uint amount) external override {
        // TOKEN_ID_AIRDROP(1) and TOKEN_ID_COIN(0) are reserved.
        require(card.id > TOKEN_ID_AIRDROP, "invalid token id");
        vipCoin.mint(to, card.id, amount, "");
    }
}
