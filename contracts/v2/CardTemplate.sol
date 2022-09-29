// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces.sol";
import "./Roles.sol";

//import "hardhat/console.sol";

//TODO:
//1.Supports enumeration function.
//2.Supports to delete a template for API provider.
//3.Access control.

/**
 * Provider manages card templates here.
 */
contract CardTemplate is ICardTemplate{
    IApp public belongsToApp;
    uint public nextId;
    mapping(uint=>Template) templates;

    function initialize(IApp belongsTo_) public {
        require(address(belongsToApp) == address(0), "already initialized");
        belongsToApp = belongsTo_;
        nextId = 10001;
    }

    function getTemplate(uint id) public override view returns (Template memory t) {
        t = templates[id];
        //console.log("get template, duration is :", t.duration);
    }

    function config(Template memory template) external {
        require(belongsToApp.hasRole(Roles.CONFIG_ROLE, msg.sender), "require config role");
        if (template.id == 0) {
            template.id = nextId;
            nextId += 1;
        } else if (template.id >= nextId) {
            revert("invalid id");
        }
        templates[template.id] = template;
    }
}
