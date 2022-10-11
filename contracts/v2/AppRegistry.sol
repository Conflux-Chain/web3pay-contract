// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./AppFactory.sol";

/**
 * @dev AppRegistry is used to manage all registered applications.
 */
contract AppRegistry is Initializable, AccessControlEnumerable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Math for uint256;

    struct AppInfo {
        address addr;
        uint256 createTime;
    }

    event Created(address indexed app, address indexed operator, address indexed owner, address apiWeightToken, address vipCoin);
    event Removed(address indexed app, address indexed operator);

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    AppFactory public appFactory;
    bool public creatorRoleDisabled; // allow any one to create app

    // app address => block.timestamp
    EnumerableMap.AddressToUintMap private _apps;
    // owner address => map(app address => block.timestamp)
    mapping(address => EnumerableMap.AddressToUintMap) private _owners;
    // user address => set(app address)
    mapping(address => EnumerableSet.AddressSet) private _users;
    ISwapExchange internal exchanger;

    // TODO supports to transfer app owner?

    constructor() {
        _disableInitializers();
    }

    function initialize(AppFactory appFactory_, ISwapExchange exchanger_) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, _msgSender());

        exchanger = exchanger_;
        appFactory = appFactory_;
    }
    function setExchanger(ISwapExchange exchanger_) public {
        require(address(exchanger) == address(0), "already set");
        exchanger = exchanger_;
    }

    function setCreatorRoleDisabled(bool disabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
        creatorRoleDisabled = disabled;
    }

    function getExchanger() external view returns (ISwapExchange) {
        return exchanger;
    }

    /**
     * @dev Creates a new application via configured factory.
     */
    function create(
        string memory name,
        string memory symbol,
        string memory link,
        string memory description,
        IApp.PaymentType paymentType_,
        uint256 deferTimeSecs,
        uint256 defaultApiWeight,
        address owner
    ) public returns (address) {
        require(creatorRoleDisabled || hasRole(CREATOR_ROLE, _msgSender()), "AppRegistry: CREATOR_ROLE required");

        address app = appFactory.create(name, symbol, link, description, paymentType_, deferTimeSecs, defaultApiWeight, owner, IAppRegistry(address(this)));

        _apps.set(app, block.timestamp);
        _owners[owner].set(app, block.timestamp);

        emit Created(app, _msgSender(), owner, IApp(app).getApiWeightToken(), IApp(app).getVipCoin());

        return app;
    }

    /**
     * @dev Removes specified `app` by owner.
     */
    function remove(address app) public {
        require(_apps.remove(app), "AppRegistry: app not found");
        require(_owners[_msgSender()].remove(app), "AppRegistry: ownership required");

        // Note, do not remove for the `_users` index for gas consideration.

        emit Removed(app, _msgSender());
    }

    function addUser(address user) public returns (bool) {
        require(_apps.contains(_msgSender()), "AppRegistry: app not registered");
        return _users[user].add(_msgSender());
    }

    function get(address app) public view returns (AppInfo memory) {
        (bool ok, uint256 createTime) = _apps.tryGet(app);
        if (!ok) {
            return AppInfo(address(0), 0);
        }

        return AppInfo(app, createTime);
    }

    function get(address owner, address app) public view returns (AppInfo memory) {
        (bool ok, uint256 createTime) = _apps.tryGet(app);
        if (!ok) {
            return AppInfo(address(0), 0);
        }

        (ok, createTime) = _owners[owner].tryGet(app);
        if (!ok) {
            return AppInfo(address(0), 0);
        }

        return AppInfo(app, createTime);
    }

    function list(uint256 offset, uint256 limit) public view returns (uint256, AppInfo[] memory) {
        return _list(_apps, offset, limit);
    }

    function listByOwner(address owner, uint256 offset, uint256 limit) public view returns (uint256, AppInfo[] memory) {
        return _list(_owners[owner], offset, limit);
    }

    function listByUser(address user, uint256 offset, uint256 limit) public view returns (uint256, AppInfo[] memory) {
        uint256 total = _users[user].length();
        if (offset >= total) {
            return (total, new AppInfo[](0));
        }

        uint256 end = total.min(offset + limit);
        AppInfo[] memory result = new AppInfo[](end - offset);

        for (uint256 i = offset; i < end; i++) {
            address addr = _users[user].at(i);
            // app may be removed by approved operator
            (bool ok, uint256 createTime) = _apps.tryGet(addr);
            if (ok) {
                result[i - offset] = AppInfo(addr, createTime);
            }
        }

        return (total, result);
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
