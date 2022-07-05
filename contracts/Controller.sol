// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./APPCoin.sol";
import "./APICoin.sol";
import "hardhat/console.sol";

contract Controller is Ownable {
    UpgradeableBeacon public appUpgradeableBeacon;
    APICoin public apiProxy;
    event APP_CREATED(address indexed addr, address indexed appOwner);
    uint256 public nextId;
    mapping(uint256=>address) public appMapping;
    constructor (){
        APICoin apiCoin = new APICoin();
        bytes memory data = abi.encodeWithSelector(APICoin.initialize.selector);
        apiProxy = APICoin(address(new ERC1967Proxy(address(apiCoin), data)));
        apiProxy.transferOwnership(msg.sender);

        APPCoin appImpl = new APPCoin();
        appUpgradeableBeacon = new UpgradeableBeacon(address(appImpl));
        appUpgradeableBeacon.transferOwnership(msg.sender);
    }
    function createApp(string memory name_, string memory symbol_) public {
        APPCoin app = APPCoin((address(new BeaconProxy(address(appUpgradeableBeacon), ""))));
        app.initOwner(address(this));
        console.log("owner of '%s' is '%s'", address(app), address(app.owner()));
        app.init(address(apiProxy), msg.sender, name_, symbol_);
        app.transferOwnership(owner());
        appMapping[nextId] = address(app);
        nextId += 1;
        emit APP_CREATED(address(app), msg.sender);
    }
    function listApp(uint offset, uint limit) public view returns (address[] memory, uint total){
        require(offset < nextId, 'invalid offset');
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
