// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IWithdrawHook {
    function withdrawEth(address receiver, uint256 ethMin) external;
}
interface IApp {
    function getAppCoin() external returns (address);
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
interface IVipCoin is IVipCoinDeposit, IVipCoinWithdraw, IERC1155{
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
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

    function getTemplate(uint id) external returns (Template memory);
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
    function makeCard(address to, Card memory card, uint amount, ICardTracker tracker) external;
}
interface ICardTracker {
    function applyCard(address from, address to, ICards.Card memory card) external;
}
