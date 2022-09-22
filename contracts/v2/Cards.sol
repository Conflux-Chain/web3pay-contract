// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@confluxfans/contracts/token/CRC1155/extensions/CRC1155Metadata.sol";
import "@confluxfans/contracts/token/CRC1155/extensions/CRC1155Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";
import "./CardTracker.sol";

//TODO access control
contract Cards is ERC1155PresetMinterPauser, CRC1155Enumerable, CRC1155Metadata {
    struct Card {
        uint id;
        uint templateId;
        string name;
        string description;
        string icon;
        uint duration;
        uint8 level;
    }
    //TODO add query functions
    //save card information.
    mapping(uint=>Card) cards;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri_
    ) ERC1155PresetMinterPauser(uri_) CRC1155Metadata(name, symbol)  {
    }

    function makeCard(address to, Card memory card, uint amount, CardTracker tracker) external {
        _mint(to, card.id, amount, "");
        cards[card.id] = card;
        tracker.applyCard(address(0), to, card);
    }

    function uri(uint256 tokenId) public view override (ERC1155, IERC1155MetadataURI) returns (string memory) {
        Card memory card = cards[tokenId];
        string memory tid = Strings.toString(card.templateId);
        string memory duration = Strings.toString(card.duration);
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
                "{\"name\":\"", card.name,
                 "\",\"image\":\"", card.icon,
                 "\",\"description\":\"", card.description,
                 "\",\"templateId\":\"",tid,
                 "\",\"duration\":\"",duration,
                 "\"}"))));
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PresetMinterPauser, CRC1155Enumerable) {
        //TODO restrict transfer
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155PresetMinterPauser, CRC1155Enumerable, IERC165)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
