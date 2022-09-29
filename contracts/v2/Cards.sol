// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";
import "./interfaces.sol";

// Use VipCoin instead.
contract Cards  {

//    function uri(uint256 tokenId) public view returns (string memory) {
//        Card memory card = cards[tokenId];
//        string memory tid = Strings.toString(card.templateId);
//        string memory duration = Strings.toString(card.duration);
//        string memory json = Base64.encode(bytes(string(abi.encodePacked(
//                "{\"name\":\"", card.name,
//                 "\",\"image\":\"", card.icon,
//                 "\",\"description\":\"", card.description,
//                 "\",\"templateId\":\"",tid,
//                 "\",\"duration\":\"",duration,
//                 "\"}"))));
//        string memory output = string(
//            abi.encodePacked("data:application/json;base64,", json)
//        );
//        return output;
//        return "";
//    }

}
