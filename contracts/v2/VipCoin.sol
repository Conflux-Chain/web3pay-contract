// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@confluxfans/contracts/token/CRC1155/extensions/CRC1155Metadata.sol";
import "@confluxfans/contracts/token/CRC1155/extensions/CRC1155Enumerable.sol";

/**
 * @dev VipCoin represents application managed coins for user to consume.
 *
 * ERC1155 standard allow applications to define multiple kinds of coins for users.
 * 
 * On the other hand, unlike a standard ERC1155 token, users could not transfer
 * tokens. Instead, it's up to privileged operator to mint, transfer or burn tokens.
 */
contract VipCoin is ERC1155PresetMinterPauser, CRC1155Enumerable, CRC1155Metadata {

    // role to transfer or burn tokens
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    ) ERC1155PresetMinterPauser(uri) CRC1155Metadata(name, symbol)  {
        _setupRole(CONSUMER_ROLE, _msgSender());
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
        override(ERC1155PresetMinterPauser, CRC1155Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
