// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@confluxfans/contracts/token/CRC1155/extensions/CRC1155Metadata.sol";
import "@confluxfans/contracts/token/CRC1155/extensions/CRC1155Enumerable.sol";
import "./TokenNameSymbol.sol";
import "./interfaces.sol";

/**
 * @dev VipCoin represents application managed coins for user to consume.
 *
 * ERC1155 standard allow applications to define multiple kinds of coins for users.
 * 
 * On the other hand, unlike a standard ERC1155 token, users could not transfer
 * tokens. Instead, it's up to privileged operator to mint, transfer or burn tokens.
 */
contract VipCoin is ERC1155PresetMinterPauser, CRC1155Enumerable, TokenNameSymbol {

    // role to transfer or burn tokens
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    IMetaBuilder public metaBuilder;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri_
    ) ERC1155PresetMinterPauser(uri_) TokenNameSymbol(name, symbol)  {
        _setupRole(CONSUMER_ROLE, _msgSender());
    }

    /** Clones call to it */
    function initialize(string memory name_, string memory symbol_, address owner, address belongsToApp, IMetaBuilder metaBuilder_) public {
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0, "already initialized");

        _name = name_;
        _symbol = symbol_;
        metaBuilder = metaBuilder_;

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(CONSUMER_ROLE, owner);
        // grant roles to app
        _grantRole(MINTER_ROLE, belongsToApp);
        _grantRole(CONSUMER_ROLE, belongsToApp);
    }

    function uri(uint tokenId) public view override returns (string memory) {
        if (address(metaBuilder) == address(0)) {
            return super.uri(tokenId);
        }
        return metaBuilder.buildMeta(tokenId);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        if (hasRole(CONSUMER_ROLE, _msgSender())) {
            // burn by privileged account
            _burn(account, id, value);
        } else {
            // burn by owner or approved account
            super.burn(account, id, value);
        }
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        if (hasRole(CONSUMER_ROLE, _msgSender())) {
            // burn by privileged account
            _burnBatch(account, ids, values);
        } else {
            // burn by owner or approved account
            super.burnBatch(account, ids, values);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PresetMinterPauser, CRC1155Enumerable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // only privileged account could transfer tokens
        if (from != address(0) && to != address(0)) {
            require(hasRole(CONSUMER_ROLE, _msgSender()), "VipCoin: CONSUMER_ROLE required");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155PresetMinterPauser, CRC1155Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
