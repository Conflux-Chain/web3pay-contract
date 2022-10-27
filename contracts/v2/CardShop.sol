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

    /**
     * call exchanger.previewDepositETH(totalPrice) to estimate how munch eth is needed.
     */
    function buyWithEth(address receiver, uint templateId, uint count) public payable {
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        require(template_.id > 0, "template not found");

        uint totalPrice = template_.price * count;
        ISwapExchange exchanger = IAppAccessor(address(belongsToApp)).appRegistry().getExchanger();
        uint needEth = exchanger.previewDepositETH(totalPrice);
        require(msg.value >= needEth, "insufficient input");

        exchanger.depositETH{value: needEth}(totalPrice, address(belongsToApp));

        _callMakeCard(receiver, template_, count, totalPrice);

        uint dust = msg.value - needEth;
        if (dust > 0) {
            (bool success,) = msg.sender.call{value : dust}(new bytes(0));
            require(success, 'CardShop: transfer ETH failed');
        }
    }
    function buyWithAsset(address receiver, uint templateId, uint count) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        require(template_.id > 0, "template not found");

        uint totalPrice = template_.price * count;
        IERC4626 erc4626 = IERC4626(belongsToApp.getAppCoin());
        uint256 assets = erc4626.previewMint(totalPrice);

        // transfer asset from msg.sender to this
        SafeERC20.safeTransferFrom(IERC20(erc4626.asset()), msg.sender, address(this), assets);
        // approve asset to app coin
        SafeERC20.safeApprove(IERC20(erc4626.asset()), address(erc4626), assets);
        // deposit for belongsToApp
        erc4626.deposit(assets, address(belongsToApp));

        _callMakeCard(receiver, template_, count, totalPrice);
    }

    function giveCardBatch(address[] memory receiverArr, uint[] memory countArr, uint templateId) public {
        require(belongsToApp.hasRole(Roles.AIRDROP_ROLE, msg.sender), "");
        ICardTemplate.Template memory template_ = template.getTemplate(templateId);
        require(template_.id > 0, "template not found");
        require(receiverArr.length == countArr.length, "invalid length");
        for(uint i=0; i<receiverArr.length; i++){
            uint cardId = _callMakeCard(receiverArr[i], template_, countArr[i], 0);
            emit GAVEN_CARD(msg.sender, receiverArr[i], cardId);
        }
    }

    function getCard(uint id) public view returns (ICards.Card memory){
        return cards[id];
    }

    function _callMakeCard(address to, ICardTemplate.Template memory template_, uint count, uint totalPrice) internal returns (uint){
        ICards.Card memory card = ICards.Card(
            nextCardId,
            (template_.duration + template_.giveawayDuration) * count, // total duration
            to, count,
            template_
        );
        nextCardId ++;
        uint TOKEN_ID_VIP = 3; // defined in App.sol. Can not access constant variable in interface.
        uint vipTokenBalance = IVipCoin(belongsToApp.getVipCoin()).balanceOf(to, TOKEN_ID_VIP);
        // only create one VIP NFT for each account.
        // if count is 0, then only apply totalPrice
        instance.makeCard(to, TOKEN_ID_VIP, vipTokenBalance == 0 ? 1 : 0, totalPrice);
        cards[card.id] = card;
        tracker.applyCard(address(0), to, card);
        return card.id;
    }
}
