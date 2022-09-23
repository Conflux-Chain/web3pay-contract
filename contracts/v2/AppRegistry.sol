// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev AppRegistry is used to manage all registered applications.
 */
contract AppRegistry is Initializable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using Math for uint256;

    struct AppInfo {
        address addr;
        uint256 createTime;
    }

    EnumerableMap.AddressToUintMap private _apps;
    mapping(address => EnumerableMap.AddressToUintMap) private _creators;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        // TODO add initialization here, e.g. ownerable
    }

    // TODO supports to create App with template
    // TODO privilege to create/remove app
    // TODO supports user level index, e.g. user paid app

    function list(uint256 offset, uint256 limit) public view returns (uint256, AppInfo[] memory) {
        return _list(_apps, offset, limit);
    }

    function list(address creator, uint256 offset, uint256 limit) public view returns (uint256, AppInfo[] memory) {
        return _list(_creators[creator], offset, limit);
    }

    function _list(EnumerableMap.AddressToUintMap storage apps,uint256 offset, uint256 limit) private view returns (uint256, AppInfo[] memory) {
        uint256 total = apps.length();
        if (offset >= total) {
            return (total, new AppInfo[](0));
        }

        uint256 end = total.min(offset + limit);
        AppInfo[] memory result = new AppInfo[](end - offset);

        for (uint256 i = offset; i < end; i++) {
            (address addr, uint256 createTime) = apps.at(i);
            result[i - offset] = AppInfo(addr, createTime);
        }

        return (total, result);
    }
}
