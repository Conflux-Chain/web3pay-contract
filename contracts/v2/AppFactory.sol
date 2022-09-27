// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AppCoinV2.sol";
import "./VipCoinFactory.sol";
import "./App.sol";
import "./AppRegistry.sol";
import "./ApiWeightTokenFactory.sol";

contract AppFactory is Initializable {

    event Created(address indexed app, address indexed operator, address indexed owner);

    AppCoinV2 public appCoin;
    VipCoinFactory public vipCoinFactory;
    ApiWeightTokenFactory public apiWeightTokenFactory;
    UpgradeableBeacon public beacon;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        AppCoinV2 appCoin_,
        VipCoinFactory vipCoinFactory_,
        ApiWeightTokenFactory apiWeightTokenFactory_,
        address beaconOwner
    ) public initializer {
        appCoin = appCoin_;
        vipCoinFactory = vipCoinFactory_;
        apiWeightTokenFactory = apiWeightTokenFactory_;

        App app = new App();
        beacon = new UpgradeableBeacon(address(app));
        beacon.transferOwnership(beaconOwner);
    }

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 deferTimeSecs,
        uint defaultApiWeight,
        address owner,
        AppRegistry appRegistry
    ) public returns (address) {
        App app = App(address(new BeaconProxy(address(beacon), "")));

        VipCoin vipCoin = VipCoin(vipCoinFactory.create(name, symbol, uri, owner, address(app)));
        ApiWeightToken apiWeightToken = ApiWeightToken(apiWeightTokenFactory.create(
            app,
            string(abi.encodePacked(name, " api")),
            string(abi.encodePacked(symbol, "_api")),
            uri, owner, defaultApiWeight
        ));

        app.initialize(appCoin, vipCoin, apiWeightToken, deferTimeSecs, owner, appRegistry);


        emit Created(address(app), msg.sender, owner);

        return address(app);
    }

}
