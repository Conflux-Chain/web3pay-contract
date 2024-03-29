// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AppCore.sol";
import "./VipCoinDeposit.sol";
import "./VipCoinWithdraw.sol";
import "./AppCoinV2.sol";
import "./interfaces.sol";
import "./Roles.sol";
import "./CardShop.sol";

/**
 * @dev App represents an application to provide API or functionality service.
 */
contract App is AppCore, VipCoinDeposit, VipCoinWithdraw, ICards {
    // role who can charge coin from user
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
        _grantRole(Roles.CHARGE_ROLE, owner);
        _grantRole(Roles.TAKE_PROFIT_ROLE, owner);
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
    function setAppInfo(string memory link_, string memory description_, uint withdrawDelay) public {
        require(hasRole(Roles.CONFIG_ROLE, msg.sender), "not permitted");
        if(paymentType == PaymentType.BILLING) {
            deferTimeSecs = withdrawDelay;
        }
        link = link_;
        description = description_;
    }
    function takeProfit(address to, uint256 amount) public onlyRole(Roles.TAKE_PROFIT_ROLE) {
        require(totalTakenProfit + amount <= totalCharged, "App: Amount exceeds");
        totalTakenProfit += amount;
        // This way doesn't present transferring funds from App to taker.
        // appCoin.redeem(amount, to, address(this));
        uint assets = appCoin.redeem(amount, address(this), address(this));
        IERC20(appCoin.asset()).transfer(to, assets);
    }

    function takeProfitAsEth(uint256 amountAppCoin, uint256 amountMinEth) public onlyRole(Roles.TAKE_PROFIT_ROLE) {
        // There is only one configured recipient by design, parameter `to` is not needed.

        require(totalTakenProfit + amountAppCoin <= totalCharged, "App: Amount exceeds");
        totalTakenProfit += amountAppCoin;

        ISwapExchange exchanger = appRegistry.getExchanger();
        _withdrawForEth(amountAppCoin, msg.sender, IWithdrawHook(address(exchanger)), amountMinEth);
    }

    /** Billing service calls it to charge for api cost. */
    function chargeBatch(IAppConfig.ChargeRequest[] memory requestArray) public onlyRole(Roles.CHARGE_ROLE) {
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

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        require(role != DEFAULT_ADMIN_ROLE || getRoleMemberCount(DEFAULT_ADMIN_ROLE) > 1, "can not revoke last one");
        super.revokeRole(role, account);
    }

    receive() external payable {}
}
