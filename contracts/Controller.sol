// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "hardhat/console.sol";
import "./Airdrop.sol";
/**
* @title Controller
* @dev DApp developers can register their app through this controller.
* An ERC777 contract will be deployed, which then will be used as a settlement contract between API consumer and API supplier.
*/

contract Controller is OwnableUpgradeable, UUPSUpgradeable {
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor () {
        _disableInitializers();
    }
    function initialize(address api_, address appBase_) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        appBase = appBase_;
        api = api_;
    }
    /* Must be called from app contract. */
    function changeAppOwner(address from, address to) external {
        address app = msg.sender;
        AppInfo[] storage ownedApps = creatorAppTrack[from];
        // find app
        uint pos = 0;
        bool find = false;
        AppInfo memory appInfo;
        for(uint i=0; i<ownedApps.length; i++) {
            if (ownedApps[i].addr == app) {
                pos = i;
                find = true;
                appInfo = ownedApps[i];
                break;
            }
        }
        if (!find) {
            revert("App not found");
        }
        // move last one to current
        AppInfo memory last = ownedApps[ownedApps.length - 1];
        ownedApps.pop();
        if (last.addr != app) {
            ownedApps[pos] = last;
        }
        // append to `to`
        creatorAppTrack[to].push(appInfo);
    }
    /**
    * @dev Create/register a DApp.
    * Will deploy an ERC777 contract, then use it as a settlement contract between API consumer and API supplier.
    * Set caller as `appOwner`.
    * There is a delayed execution mechanism when configuring resources. It is best to set default weights at creation time.
    */
    function createApp(string memory name_, string memory symbol_, string memory description_, uint256 defaultWeight) public {
        Airdrop app = Airdrop((address(new BeaconProxy(address(appBase), ""))));
        app.initOwner(address(this));
        app.init(api, msg.sender, name_, symbol_, description_, defaultWeight);
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

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}
// reference to: https://forum.openzeppelin.com/t/how-to-deploy-new-instances-using-beacon-proxy-from-a-factory-when-using-openzeppelin-hardhat-upgrades/27801/5
