// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./ApiWeightToken.sol";
import "./App.sol";

contract ApiWeightTokenFactory is Initializable{
    event Created(address indexed app, address indexed operator, address indexed owner);

    UpgradeableBeacon public beacon;

    constructor() {
        _disableInitializers();
    }

    function initialize(address appConfigImpl, address beaconOwner) public initializer {
        beacon = new UpgradeableBeacon(address(appConfigImpl));
        beacon.transferOwnership(beaconOwner);
    }

    function create(
        App belongsTo,
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        uint defaultWeight
    ) public returns (address) {
        ApiWeightToken appConfig = ApiWeightToken(address(new BeaconProxy(address(beacon), "")));

        appConfig.initialize(belongsTo, name, symbol, uri, owner, defaultWeight);

        emit Created(address(appConfig), msg.sender, owner);

        return address(appConfig);
    }
}
