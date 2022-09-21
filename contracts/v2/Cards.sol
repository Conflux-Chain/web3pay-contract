// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Interfaces.sol";

import "hardhat/console.sol";

contract Cards is ICard{
    uint nextId = 1;
    mapping(uint=>Card) packages;

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

    function makeCard(address to, Card memory t, ICardTracker tracker) external override{
        t.id = nextId;
        nextId += 1;
        packages[t.id] = t;

        _balances[to] += 1;
        _owners[t.id] = to;
        tracker.track(address(0), to, t);
        emit Transfer(address(0), to, t.id);
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
        ICard.Card memory p = packages[tokenId];
        string memory tid = Strings.toString(p.templateId);
        string memory duration = Strings.toString(p.duration);
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
                "{\"name\":\"",p.name,
                 "\",\"image\":\"",p.icon,
                 "\",\"description\":\"",p.description,
                 "\",\"templateId\":\"",tid,
                 "\",\"duration\":\"",duration,
                 "\"}"))));
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }
}
