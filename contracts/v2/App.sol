// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AppCore.sol";
import "./VipCoinDeposit.sol";
import "./VipCoinWithdraw.sol";
import "./AppCoinV2.sol";
import "./interfaces.sol";
import "./CardShop.sol";

/**
 * @dev App represents an application to provide API or functionality service.
 */
contract App is AppCore, VipCoinDeposit, VipCoinWithdraw, ICards {
    // role who can charge coin from user
    bytes32 public constant CHARGE_ROLE = keccak256("CHARGE_ROLE");
    bytes32 public constant TAKE_PROFIT_ROLE = keccak256("TAKE_PROFIT_ROLE");
    uint256 public constant TOKEN_ID_VIP = 3; // only one NFT for VIP
    // totalCharged fees produced by billing
    uint256 public totalCharged;
    address public cardShop;
    uint256 public totalTakenProfit;
    string public link;
    string public description;
    PaymentType public paymentType;// 0: none; 1: billing; 2: subscribe;

    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(AppCoinV2 appCoin_, IVipCoin vipCoin_, address apiWeightToken_, uint256 deferTimeSecs_, address owner, IAppRegistry appRegistry_) public override initializer {
        __AppCore_init(appCoin_, vipCoin_, apiWeightToken_, owner);
        __VipCoinDeposit_init(owner, appRegistry_);
        __VipCoinWithdraw_init(deferTimeSecs_, owner);
        _grantRole(Roles.CONFIG_ROLE, owner);
        _grantRole(CHARGE_ROLE, owner);
        _grantRole(TAKE_PROFIT_ROLE, owner);
    }

    // avoid stack too deep
    function setProps(
        address cardShop_, string memory link_, string memory description_, PaymentType paymentType_
    ) public override {
        // initialize by factory, or setProps by config_role
        require(cardShop == address(0) || hasRole(Roles.CONFIG_ROLE, msg.sender), "not permitted");
        require(paymentType_ == PaymentType.BILLING || paymentType_ == PaymentType.SUBSCRIBE, "invalid payment type");
        if (cardShop == address(0)) {
            cardShop = cardShop_;
        }
        link = link_;
        description = description_;
        paymentType = paymentType_;
    }

    function takeProfit(address to, uint256 amount) public onlyRole(TAKE_PROFIT_ROLE) {
        require(totalTakenProfit + amount <= totalCharged, "Amount exceeds");
        totalTakenProfit += amount;
        appCoin.redeem(amount, to, address(this));
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

        IApiWeightToken(apiWeightToken).addRequestTimes(account, useDetail);

        if (withdrawSchedules[account] > 1) {
            // refund
            _withdraw(msg.sender, account, account, true);
        }
    }

    function makeCard(address to, uint tokenId, uint amount, uint totalPrice) external override {
        if (amount > 0) { // when amount is 0, only apply totalPrice.
            // TOKEN_ID_AIRDROP(1) and TOKEN_ID_COIN(0) are reserved.
            require(tokenId > TOKEN_ID_AIRDROP, "invalid token id");
            vipCoin.mint(to, tokenId, amount, "");
        }

        totalCharged += totalPrice;

        appRegistry.addUser(to);
    }
}
