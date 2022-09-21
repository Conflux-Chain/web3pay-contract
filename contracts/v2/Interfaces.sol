// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITemplate {
    struct Template {
        uint id;
        string name;
        string description;
        string icon;
        uint duration;
        uint price;
        uint showPrice;
        uint   openSaleAt;
        uint   closeSaleAt;
        uint8  status;
        uint   salesLimit;
        uint8 level;
    }

    function getTemplate(uint id) external returns (Template memory);
}
interface ICard {
    struct Card {
        uint id;
        uint templateId;
        string name;
        string description;
        string icon;
        uint duration;
        uint8 level;
    }
    function makeCard(address to, Card memory t) external;
}
