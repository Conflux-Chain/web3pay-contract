// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Cards.sol";
import "./CardTemplate.sol";
import "./CardTracker.sol";

//import "hardhat/console.sol";

//TODO access control
contract CardShop {
    CardTemplate public template;
    Cards public instance;
    CardTracker public tracker;
    function initialize(CardTemplate template_, Cards instance_, CardTracker tracker_) public {
        template = template_;
        instance = instance_;
        tracker = tracker_;
    }
    function buy(uint templateId) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        CardTemplate.Template memory t = template.getTemplate(templateId);
        require(t.id>0, "template not found");
        Cards.Card memory card = Cards.Card(
            templateId,//id
            templateId,
            t.name,
            t.description,
            t.icon,
            t.duration,
            t.level
        );
        //TODO buy more than 1 at once
        instance.makeCard(msg.sender, card, 1, tracker);
    }
}
