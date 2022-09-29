// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interfaces.sol";
import "./Roles.sol";
//import "hardhat/console.sol";

//TODO access control
contract CardShop {
    IApp public belongsToApp;
    ICardTemplate public template;
    ICards public instance;
    ICardTracker public tracker;

    //TODO add query functions
    //save card information.
    mapping(uint=>ICards.Card) cards;

    event GAVEN_CARD(address indexed operator, address indexed to, uint cardId);

    function initialize(IApp belongsTo_, ICardTemplate template_, ICards instance_, ICardTracker tracker_) public {
        require(address(belongsToApp) == address(0), "already initialized");
        template = template_;
        instance = instance_;
        tracker = tracker_;
        belongsToApp = belongsTo_;
    }

    function buy(address receiver, uint templateId) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        //TODO complete payment
        require(template_.id > 0, "template not found");
        _callMakeCard(receiver, template_);
    }

    function giveCard(address receiver, uint templateId) public {
        require(belongsToApp.hasRole(Roles.AIRDROP_ROLE, msg.sender), "");
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        require(template_.id > 0, "template not found");
        uint cardId = _callMakeCard(receiver, template_);
        emit GAVEN_CARD(msg.sender, receiver, cardId);
    }

    function getCard(uint id) public view returns (ICards.Card memory){
        return cards[id];
    }

    function _callMakeCard(address to, ICardTemplate.Template memory template_) internal returns (uint){
        uint cardId = template_.id; //TODO add algorithm
        ICards.Card memory card = ICards.Card(
            cardId,
            template_.id,
            template_.name,
            template_.description,
            template_.icon,
            template_.duration,
            template_.level
        );
        //TODO buy more than 1 at once
        instance.makeCard(to, card, 1);
        cards[cardId] = card;
        tracker.applyCard(address(0), to, card);
        return cardId;
    }

    function upgradeVip(address account, uint templateId) public {
        uint fee;
        uint addedDuration;
        (fee, addedDuration) = getUpgradeFee(account, templateId);
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        //TODO complete payment
        template_.duration = addedDuration;
        _callMakeCard(account, template_);
    }

    /** Calculate how much a membership upgrade will cost  */
    function getUpgradeFee(address account, uint templateId) public view returns (uint price, uint addedDuration){
        ICardTemplate.Template memory nextTemplate = template.getTemplate(templateId);
        ICardTracker.VipInfo memory curVipInfo = tracker.getVipInfo(account);
        if (curVipInfo.level == 0 || curVipInfo.expireAt < block.timestamp) {
            // not at valid vip level, treat as buy nextTemplate directly.
            return (nextTemplate.price, nextTemplate.duration);
        }
        require(curVipInfo.level + 1 == nextTemplate.level, "discontinuous" );
        uint partialDuration = curVipInfo.expireAt - block.timestamp;
        require( partialDuration <= nextTemplate.duration, "exceeds duration");

        return (nextTemplate.price * partialDuration / nextTemplate.duration, 0);
    }
}
