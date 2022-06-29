// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IAPPCoin.sol";
contract APICoin is Initializable, ERC777Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    //
    function depositToApp(address appCoin) public payable {
        require(msg.value > 0, 'Zero value');
        require(IAPPCoin(appCoin).apiCoin() == address(this), 'Invalid app');
        _mint(msg.sender, msg.value, '','');
        send(appCoin, msg.value, "");
    }
    function refund(uint256 amount) public {
        super.burn(amount, "");
        payable(msg.sender).transfer(amount);
    }
    //----------------------- OpenZeppelin code --------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        address[] memory defaultOperators = new address[](0);
        __ERC777_init("API Coin", "APIC", defaultOperators);
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