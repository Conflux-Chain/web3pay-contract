// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/**
 * Card template registry.
 */
interface ITemplateRegistry {
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
interface ICardFactory {
    struct Card {
        uint id;
        uint templateId;
        string name;
        string description;
        string icon;
        uint duration;
        uint8 level;
    }
    function makeCard(address to, Card memory t, ICardTracker tracker) external;
}
interface ICardTracker {
    function applyCard(address from, address to, ICardFactory.Card memory pkg) external;
}
