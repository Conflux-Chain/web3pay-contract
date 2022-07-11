// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./APPCoin.sol";
import "hardhat/console.sol";
/**
* @title Controller
* @dev DApp developers can register their app through this controller.
* An ERC777 contract will be deployed, which then will be used as a settlement contract between API consumer and API supplier.
*/

contract Controller is Ownable {
    address public appBase;
    address public api;
    /** @dev APP_CREATED event */
    event APP_CREATED(address indexed addr, address indexed appOwner);
    uint256 public nextId;
    mapping(uint256=>address) public appMapping;

    struct AppInfo {
        address addr;
        uint256 blockTime;
    }
    mapping(address=>AppInfo[]) creatorAppTrack;

    constructor (address api_){
        APPCoin appImpl = new APPCoin();
        UpgradeableBeacon appUpgradeableBeacon = new UpgradeableBeacon(address(appImpl));
        appUpgradeableBeacon.transferOwnership(msg.sender);
        appBase = address(appUpgradeableBeacon);
        api = api_;
    }
    /**
    * @dev Create/register a DApp.
    * An ERC777 contract will be deployed, which then will be used as a settlement contract between API consumer and API supplier.
    * Caller's address will be used as the `appOwner` of the contract.
    */
    function createApp(string memory name_, string memory symbol_) public {
        APPCoin app = APPCoin((address(new BeaconProxy(address(appBase), ""))));
        app.initOwner(address(this));
        app.init(api, msg.sender, name_, symbol_);
        app.transferOwnership(owner());
        appMapping[nextId] = address(app);
        nextId += 1;
        // track this creator's app.
        creatorAppTrack[msg.sender].push(AppInfo(address(app), block.timestamp));

        emit APP_CREATED(address(app), msg.sender);
    }
    function listAppByCreator(address creator_, uint32 offset, uint limit) public view returns (AppInfo[] memory apps, uint256 total) {
        AppInfo[] memory createdApp = creatorAppTrack[creator_];
        if (offset == 0 && limit >= createdApp.length) {
            return (createdApp, createdApp.length);
        }
        require(offset <= createdApp.length, 'invalid offset');
        if (offset + limit >= createdApp.length) {
            limit = createdApp.length - offset;
        }
        AppInfo[] memory arr = new AppInfo[](limit);
        for(uint i=0; i<limit; i++) {
            arr[i] = createdApp[offset];
            offset += 1;
        }
        return (arr, createdApp.length);
    }
    /** @dev List created DApp settlement contracts. */
    function listApp(uint offset, uint limit) public view returns (address[] memory, uint total){
        require(offset <= nextId, 'invalid offset');
        if (offset + limit >= nextId) {
            limit = nextId - offset;
        }
        address[] memory arr = new address[](limit);
        for(uint i=0; i<limit; i++) {
            arr[i] = appMapping[offset];
            offset += 1;
        }
        return (arr, nextId);
    }
}
// reference to: https://forum.openzeppelin.com/t/how-to-deploy-new-instances-using-beacon-proxy-from-a-factory-when-using-openzeppelin-hardhat-upgrades/27801/5
