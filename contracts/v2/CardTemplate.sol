// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";

//TODO:
//1.Supports enumeration function.
//2.Supports to delete a template for API provider.
//3.Access control.

/**
 * Provider manages card templates here.
 */
contract CardTemplate {
    struct Template {
        uint id;
        string name;
        string description;
        string icon;
        uint duration;
        uint price;  // actual selling price
        uint8  status; //TODO enum status
        uint8 level;
    }
    uint public nextId = 1;
    mapping(uint=>Template) templates;

    function getTemplate(uint id) public view returns (Template memory t) {
        t = templates[id];
        //console.log("get template, duration is :", t.duration);
    }

    function config(Template memory template) external {
        if (template.id == 0) {
            template.id = nextId;
            nextId += 1;
        } else if (template.id >= nextId) {
            revert("invalid id");
        }
        templates[template.id] = template;
    }
}
