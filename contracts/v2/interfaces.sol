// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./AppCoinV2.sol";

interface ISwapExchange {
    function previewDepositETH(uint256 amount) external view returns (uint256);
    function depositETH(uint256 amount, address receiver) external payable;
}
interface IWithdrawHook {
    function withdrawEth(address receiver, uint256 ethMin) external;
}
interface IApp is IAccessControl{
    function getAppCoin() external view returns (address);
    function getVipCoin() external view returns (address);
    function initialize(
        AppCoinV2 appCoin_, IVipCoin vipCoin_, address apiWeightToken_,
        uint256 deferTimeSecs_,
        address owner, IAppRegistry appRegistry_) external;
    function setProps(
        address cardShop_, string memory link_, string memory description_, PaymentType paymentType_
    ) external;

    function getApiWeightToken() external view returns(address);

    enum PaymentType{
        NONE, BILLING, SUBSCRIBE
    }
}

interface IAppRegistry {
    function addUser(address user) external returns (bool);
    function getExchanger() external view returns (ISwapExchange);

    struct AppInfo {
        address addr;
        uint256 createTime;
    }
    function listByUser(address user, uint256 offset, uint256 limit) external view returns (uint256 total, AppInfo[] memory list);
}
interface IVipCoinDeposit {
    function balanceOf(address account) external view returns (uint256, uint256);
    function deposit(uint256 amount, address receiver) external;
}
interface IAppAccessor {
    function appRegistry() external view returns (IAppRegistry);
    function link() external view returns (string memory);
    function paymentType() external view returns (IApp.PaymentType type_);
    function cardShop() external view returns (ICardShopAccessor);
}
interface ICardShopAccessor {
    function tracker() external view returns (ICardTracker tracker_);
}
interface IVipCoinWithdraw {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external ;
    function deferTimeSecs() external view returns(uint);
    function withdrawSchedules(address who) external view returns(uint);
}
interface IVipCoin is IERC1155{
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

interface ICardTemplate {
    // copying struct array is not supported, but copying primitive array is.
    struct Props {
        string[] keys;
        string[] values;
    }
    /** Card template */
    struct Template {
        uint id;
        string name;
        string description;
        uint price;  // actual selling price
        uint duration; // uint: second
        uint giveawayDuration;
        Props props;
    }

    function getTemplate(uint id) external view returns (Template memory);
}
interface ICards {
    struct Card {
        uint id;
        uint duration;
        address owner;
        uint count;
        ICardTemplate.Template template;
    }
    function makeCard(address to, uint tokenId, uint amount, uint totalPrice) external;
}
interface ICardTracker {
    struct VipInfo {
        uint expireAt;
        ICardTemplate.Props props;
        string name;
    }
    function getVipInfo(address account) external view returns (VipInfo memory);
    function applyCard(address from, address to, ICards.Card memory card) external;
}
interface IAppConfig {
    struct ResourceUseDetail {
        uint32 id;
        uint256 times;
    }
    struct ChargeRequest {
        address account;
        uint256 amount;
        bytes data;
        /* resource consumed under this charge */
        ResourceUseDetail[] useDetail;
    }
    struct ConfigEntry {
        string resourceId;
        uint256 weight;
        uint32 index; // index in indexArray
        // pending action
        OP pendingOP;
        uint256 pendingWeight;
        /* when the pending action was submitted */
        uint submitSeconds;
        uint256 requestTimes;
    }
    /** Operation code for configuring resources, ADD 0; UPDATE: 1; DELETE: 2 */
    enum OP {ADD/*0*/,UPDATE/*1*/,DELETE/*2*/, NO_PENDING/*3*/, PENDING_INIT_DEFAULT/*4*/}
}
interface IVipCoinFactory {
    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        address app
    ) external returns (address);
}
interface ICardShopFactory {
    function create(IApp belongsTo) external returns (address);
}
interface IApiWeightToken {
    function addRequestTimes(address account, IAppConfig.ResourceUseDetail[] memory useDetail) external;
}
interface IApiWeightTokenFactory {
    function create(
        IApp belongsTo,
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        uint defaultWeight
    ) external returns (address);
}
