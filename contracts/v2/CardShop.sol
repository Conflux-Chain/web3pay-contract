// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Interfaces.sol";

//import "hardhat/console.sol";

contract CardShop {
    ITemplate template;
    ICard instance;
    ICardTracker tracker;
    function setContracts(ITemplate template_, ICard instance_, ICardTracker tracker_) public {
        template = template_;
        instance = instance_;
        tracker = tracker_;
    }
    function buy(uint templateId) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        ITemplate.Template memory t = template.getTemplate(templateId);
        require(t.id>0);
        ICard.Card memory p = ICard.Card(
            0,//id
            templateId,
            t.name,
            t.description,
            t.icon,
            t.duration,
            t.level
        );
        instance.makeCard(msg.sender, p, tracker);
    }
}
