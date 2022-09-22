// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Interfaces.sol";

//import "hardhat/console.sol";

contract CardShop {
    ITemplateRegistry public template;
    ICardFactory public instance;
    ICardTracker public tracker;
    function initialize(ITemplateRegistry template_, ICardFactory instance_, ICardTracker tracker_) public {
        template = template_;
        instance = instance_;
        tracker = tracker_;
    }
    function buy(uint templateId) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        ITemplateRegistry.Template memory t = template.getTemplate(templateId);
        require(t.id>0);
        ICardFactory.Card memory card = ICardFactory.Card(
            0,//id
            templateId,
            t.name,
            t.description,
            t.icon,
            t.duration,
            t.level
        );
        instance.makeCard(msg.sender, card, tracker);
    }
}
