// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interfaces.sol";

//import "hardhat/console.sol";

//TODO access control
contract CardShop {
    ICardTemplate public template;
    ICards public instance;
    ICardTracker public tracker;
    function initialize(ICardTemplate template_, ICards instance_, ICardTracker tracker_) public {
        template = template_;
        instance = instance_;
        tracker = tracker_;
    }
    function buy(uint templateId) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        require(template_.id>0, "template not found");
        ICards.Card memory card = ICards.Card(
            templateId,//id
            templateId,
            template_.name,
            template_.description,
            template_.icon,
            template_.duration,
            template_.level
        );
        //TODO buy more than 1 at once
        instance.makeCard(msg.sender, card, 1, tracker);
    }
}
