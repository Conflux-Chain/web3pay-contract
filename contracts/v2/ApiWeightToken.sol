// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../AppConfig.sol";
import "./TokenNameSymbol.sol";
import "./interfaces.sol";

/**
 * Config api weights and display as 1155 NFT.
 */
contract ApiWeightToken is ERC1155, ERC1155Holder, AccessControlEnumerable, TokenNameSymbol, AppConfig {
    // role to configure resource weight
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    IApp public belongsToApp;

    constructor(
        IApp belongsTo,
        string memory name,
        string memory symbol,
        string memory uri
    ) ERC1155(uri) TokenNameSymbol(name, symbol)  {
        belongsToApp = belongsTo;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(CONFIG_ROLE, _msgSender());
    }

    function initialize(
        IApp belongsTo,
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        uint defaultWeight
    ) public {
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0 || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not rights");
        belongsToApp = belongsTo;
        _name = name;
        _symbol = symbol;
        _setURI(uri);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(CONFIG_ROLE, owner);

        pendingSeconds = 3600 * 24 * 7;
        nextConfigId = FIRST_CONFIG_ID;
        ConfigRequest memory request = ConfigRequest(0, "default", defaultWeight, OP.ADD);
        _configResource(request);
        _flushPendingConfig(0);
    }

    /**
     * In order to facilitate debugging, a delayed effective time interval can be set.
     * It is required that the asset token is an address on testnet.
     */
    function setPendingSeconds(uint seconds_) public {
        // hardcoded address is the faucet usdt on testnet.
        require(IERC4626(belongsToApp.getAppCoin()).asset() == 0x7d682e65EFC5C13Bf4E394B8f376C48e6baE0355, "only for testnet");
        pendingSeconds = seconds_;
    }

    function _mintConfig(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        _mint(to, id, amount, data);
    }
    function _burnConfig(
        address from,
        uint256 id,
        uint256 amount
    ) internal override {
        _burn(from, id, amount);
    }

    // prevent transfer
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155){
        require(from == address(0) || to == address(0), 'not allow');
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC1155Receiver, AccessControlEnumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeAppConfig() internal view override {
        require(hasRole(CONFIG_ROLE, _msgSender()), "require config role");
    }
}
