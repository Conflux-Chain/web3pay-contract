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

    uint public nextCardId; //starts from 0
    //save card information.
    mapping(uint=>ICards.Card) cards;

    event GAVEN_CARD(address indexed operator, address indexed to, uint cardId);

    function initialize(IApp belongsTo_, ICardTemplate template_, ICards instance_, ICardTracker tracker_) public {
        require(address(belongsToApp) == address(0), "already initialized");
        template = template_;
        instance = instance_;
        tracker = tracker_;
        belongsToApp = belongsTo_;
        nextCardId = 0;
    }

    function buy(address receiver, uint templateId, uint count) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        //TODO complete payment
        require(template_.id > 0, "template not found");
        _callMakeCard(receiver, template_, count);
    }

    function giveCardBatch(address[] memory receiverArr, uint[] memory countArr, uint templateId) public {
        require(belongsToApp.hasRole(Roles.AIRDROP_ROLE, msg.sender), "");
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        require(template_.id > 0, "template not found");
        require(receiverArr.length == countArr.length, "invalid length");
        for(uint i=0; i<receiverArr.length; i++){
            uint cardId = _callMakeCard(receiverArr[i], template_, countArr[i]);
            emit GAVEN_CARD(msg.sender, receiverArr[i], cardId);
        }
    }

    function getCard(uint id) public view returns (ICards.Card memory){
        return cards[id];
    }

    function _callMakeCard(address to, ICardTemplate.Template memory template_, uint count) internal returns (uint){
        ICards.Card memory card = ICards.Card(
            nextCardId,
            (template_.duration + template_.giveawayDuration) * count, // total duration
            to, count,
            template_
        );
        nextCardId ++;
        uint TOKEN_ID_VIP = 3; // defined in App.sol. Can not access constant variable in interface.
        uint vipTokenBalance = IVipCoin(belongsToApp.getVipCoin()).balanceOf(to, TOKEN_ID_VIP);
        if (vipTokenBalance == 0) { // only create one VIP NFT for each account.
            instance.makeCard(to, TOKEN_ID_VIP, 1);
        }
        cards[card.id] = card;
        tracker.applyCard(address(0), to, card);
        return card.id;
    }
}
