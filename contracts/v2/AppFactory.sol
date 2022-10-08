// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AppCoinV2.sol";
import "./VipCoinFactory.sol";
import "./App.sol";
import "./ApiWeightTokenFactory.sol";
import "./CardShopFactory.sol";

contract AppFactory is Initializable {

    event Created(address indexed app, address indexed operator, address indexed owner);

    AppCoinV2 public appCoin;
    IVipCoinFactory public vipCoinFactory;
    IApiWeightTokenFactory public apiWeightTokenFactory;
    ICardShopFactory public cardShopFactory;
    UpgradeableBeacon public beacon;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        AppCoinV2 appCoin_,
        IVipCoinFactory vipCoinFactory_,
        IApiWeightTokenFactory apiWeightTokenFactory_,
        ICardShopFactory cardShopFactory_,
        address appBeacon_
    ) public initializer {
        appCoin = appCoin_;
        vipCoinFactory = vipCoinFactory_;
        apiWeightTokenFactory = apiWeightTokenFactory_;
        cardShopFactory = cardShopFactory_;

        beacon = appBeacon_;
    }

    function create(
        string memory name,
        string memory symbol,
        string memory link,
        string memory description,
        uint256 deferTimeSecs,
        uint defaultApiWeight,
        address owner,
        IAppRegistry appRegistry
    ) public returns (address) {
        IApp app = IApp(address(new BeaconProxy(address(beacon), "")));

        IVipCoin vipCoin = IVipCoin(vipCoinFactory.create(name, symbol, "", owner, address(app)));

        address apiWeightToken = apiWeightTokenFactory.create(
            app,
            string(abi.encodePacked(name, " api")),
            string(abi.encodePacked(symbol, "_api")),
                "", owner, defaultApiWeight
        );

        address cardShop = cardShopFactory.create(app);

        // stack too deep error may occur if put two steps together.
        app.initialize(appCoin, vipCoin, apiWeightToken, deferTimeSecs, owner, appRegistry);
        app.setProps(cardShop, link, description);

        emit Created(address(app), msg.sender, owner);

        return address(app);
    }

}
