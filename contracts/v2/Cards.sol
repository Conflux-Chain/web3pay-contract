// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Interfaces.sol";

import "hardhat/console.sol";

contract Cards is ICardFactory {
    uint nextId = 1;
    mapping(uint=>Card) cards;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function makeCard(address to, Card memory card, ICardTracker tracker) external override{
        card.id = nextId;
        nextId += 1;
        cards[card.id] = card;

        _balances[to] += 1;
        _owners[card.id] = to;
        tracker.applyCard(address(0), to, card);
        emit Transfer(address(0), to, card.id);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        ICardFactory.Card memory card = cards[tokenId];
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
}
