// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Interfaces.sol";

//import "hardhat/console.sol";

contract CardTemplate is ITemplate{
    uint public nextId = 1;
    mapping(uint=>Template) templates;

    function getTemplate(uint id) public view override returns (Template memory t) {
        t = templates[id];
        //console.log("get template, duration is :", t.duration);
    }

    function config(Template memory t) external {
        if (t.id == 0) {
            t.id = nextId;
            nextId += 1;
        }
        templates[t.id] = t;
    }
}
