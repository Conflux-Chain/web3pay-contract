// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces.sol";
import "./CardTemplate.sol";
import "./CardTracker.sol";
import "./CardShop.sol";

contract CardShopFactory is Initializable {

    UpgradeableBeacon public shopBeacon;
    UpgradeableBeacon public templateBeacon;
    UpgradeableBeacon public trackerBeacon;

    function initialize(UpgradeableBeacon shop, UpgradeableBeacon template, UpgradeableBeacon tracker) public initializer {
        shopBeacon = shop;
        templateBeacon = template;
        trackerBeacon = tracker;
    }
    function create(IApp belongsTo) public returns (address){
        CardTemplate template = CardTemplate(address(new BeaconProxy(address(templateBeacon), "")));
        template.initialize(belongsTo);

        CardShop shop = CardShop(address(new BeaconProxy(address(shopBeacon), "")));

        CardTracker tracker = CardTracker(address(new BeaconProxy(address(trackerBeacon), "")));
        tracker.initialize(address(shop));

        shop.initialize(belongsTo, template, ICards(address(belongsTo)), tracker);

        return address(shop);
    }
}