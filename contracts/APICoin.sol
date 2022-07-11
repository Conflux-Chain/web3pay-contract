// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IAPPCoin.sol";
/** @dev API coin is the currency in the whole payment service.
 *
 * For api consumer:
 * - depositToApp
 * - refund
 *
 * For api supplier:
 * - refund
 *
 */
contract APICoin is Initializable, ERC777Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /** @dev Used by API consumer to deposit for specified app.
     *
     * For now it only takes CFX, and 1 CFX exchanges 1 APP Coin.
     *
     * API supplier may set `price/weight` for each API, so, how many requests could be made depends on both the deposited funds and
     * the `price/weight` of consumed API.
     *
     * Parameter `appCoin` is the settlement contract of the app, please contact API supplier to get it.
     */
    function depositToApp(address appCoin) public payable {
        require(msg.value > 0, 'Zero value');
        require(IAPPCoin(appCoin).apiCoin() == address(this), 'Invalid app');
        _mint(msg.sender, msg.value, '','');
        send(appCoin, msg.value, "");
    }
    /** @dev Used by anyone who holds API coin to exchange CFX back. */
    function refund(uint256 amount) public {
        super.burn(amount, "refund");
        payable(msg.sender).transfer(amount);
    }
    //----------------------- OpenZeppelin code --------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, address[] calldata defaultOperators) initializer public {
        __ERC777_init(name_, symbol_, defaultOperators);
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}