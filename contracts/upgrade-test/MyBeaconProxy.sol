// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/Clones.sol";

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/** Use this contract to flatten BeaconProxy, and then verify on scan. */
contract MyBeaconProxy is BeaconProxy{
    constructor (address impl) BeaconProxy(impl, "") {

    }
}
contract MyClone {
    function clone() public {
        Clones.clone(address(0));
    }
}
