// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./AppCoinV2.sol";

interface IWithdrawHook {
    function withdrawEth(address receiver, uint256 ethMin) external;
}
interface IApp is IAccessControl{
    function getAppCoin() external returns (address);
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
}
interface IVipCoinDeposit {
    function balanceOf(address account) external view returns (uint256, uint256);
    function deposit(uint256 amount, address receiver) external;
}
interface IVipCoinWithdraw {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external ;
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
    /** Card template */
    struct Template {
        uint id;
        string name;
        string description;
        string icon;
        uint duration;
        uint price;  // actual selling price
        uint listPrice; // list price
        uint   openSaleAt;
        uint   closeSaleAt;
        uint8  status;
        uint   salesLimit;
        uint8 level;
    }

    function getTemplate(uint id) external view returns (Template memory);
}
interface ICards {
    struct Card {
        uint id;
        uint templateId;
        string name;
        string description;
        string icon;
        uint duration;
        uint8 level;
    }
    function makeCard(address to, Card memory card, uint amount) external;
}
interface ICardTracker {
    struct VipInfo {
        uint expireAt;
        uint8 level; // starts from 1
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
