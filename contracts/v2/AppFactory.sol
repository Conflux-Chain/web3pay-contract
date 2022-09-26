// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./AppCoinV2.sol";
import "./VipCoinFactory.sol";
import "./App.sol";
import "./AppRegistry.sol";

contract AppFactory is Initializable {

    event Created(address indexed app, address indexed operator, address indexed owner);

    AppCoinV2 public appCoin;
    VipCoinFactory public vipCoinFactory;
    UpgradeableBeacon public beacon;

    constructor() {
        _disableInitializers();
    }

    function initialize(AppCoinV2 appCoin_, VipCoinFactory vipCoinFactory_, address beaconOwner) public initializer {
        appCoin = appCoin_;
        vipCoinFactory = vipCoinFactory_;

        App app = new App();
        beacon = new UpgradeableBeacon(address(app));
        beacon.transferOwnership(beaconOwner);
    }

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 deferTimeSecs,
        address owner,
        AppRegistry appRegistry
    ) public returns (address) {
        VipCoin vipCoin = VipCoin(vipCoinFactory.create(name, symbol, uri, owner));

        App app = App(address(new BeaconProxy(address(beacon), "")));
        app.initialize(appCoin, vipCoin, deferTimeSecs, owner, appRegistry);

        // grant roles of vip coin to app
        vipCoin.grantRole(vipCoin.MINTER_ROLE(), address(app));
        vipCoin.grantRole(vipCoin.CONSUMER_ROLE(), address(app));

        emit Created(address(app), msg.sender, owner);

        return address(app);
    }

}
