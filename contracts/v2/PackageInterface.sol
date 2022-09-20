// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface PackageInterface {
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
    }
    struct Package {
        uint id;
        uint templateId;
        string name;
        string description;
        string icon;
        uint duration;
    }
    function getTemplate(uint id) external returns (Template memory);
    function makePackage(address to, Package memory t) external;
}
