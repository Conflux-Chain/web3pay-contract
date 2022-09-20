// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./PackageInterface.sol";

//import "hardhat/console.sol";

contract PackageTemplate {
    uint public nextId = 1;
    mapping(uint=>PackageInterface.Template) templates;

    function getTemplate(uint id) public view returns (PackageInterface.Template memory t) {
        t = templates[id];
        //console.log("get template, duration is :", t.duration);
    }

    function config(PackageInterface.Template memory t) external {
        if (t.id == 0) {
            t.id = nextId;
            nextId += 1;
        }
        templates[t.id] = t;
    }
}
