// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import "./interfaces.sol";
import "./Constant.sol";
import "./Roles.sol";

/** Helper functions for reading. */
contract ReadFunctions is Initializable, IMetaBuilder {
    struct UserApp {
        address app;
        string name;
        string symbol;
        string link;
        IApp.PaymentType paymentType_;
        string vipCardName;
        uint vipExpireAt;
        uint balance;
        uint airdrop;
        uint deferTimeSecs; // How long to wait for forceWithdraw
        uint withdrawSchedule; // When is forceWithdraw requested
        ICardShopAccessor cardShop;
    }
    struct RoleInfo {
        string name;
        bytes32 hash;
        address[] members;
    }

    IAppRegistry public registry;
    address public owner;
    mapping(uint=>string) public nftMeta;

    constructor() {
        _disableInitializers();
    }

    function initialize(IAppRegistry reg_) public initializer {
        registry = reg_;
    }
    function setOwner(address to) public {
        require(owner == address(0), "already set");
        owner = to;
    }
    function setMeta(uint[] memory ids, string[] memory contents) public {
        require(owner == msg.sender, "not owner");
        require(ids.length == contents.length, "length mismatch");
        for(uint i=0; i<ids.length; i++) {
            nftMeta[ids[i]] = contents[i];
        }
    }
    function buildMeta(uint tokenId) external view override returns (string memory) {
        return nftMeta[tokenId];
    }

    function appRoleMembers(IAccessControlEnumerable app, bytes32 role, string memory name) public view returns (RoleInfo memory info){
        uint count = app.getRoleMemberCount(role);
        address[] memory members = new address[](count);
        for(uint i=0; i<count; i++) {
            members[i] = app.getRoleMember(role, i);
        }
        return RoleInfo(name, role, members);
    }
    function appRoles(IAccessControlEnumerable app) public view returns (RoleInfo[] memory members2d){
        members2d = new RoleInfo[](5);
        members2d[0] = appRoleMembers(app, 0x00, "DEFAULT_ADMIN_ROLE"); // default admin role
        members2d[1] = appRoleMembers(app, Roles.CONFIG_ROLE, "CONFIG_ROLE");
        members2d[2] = appRoleMembers(app, Roles.AIRDROP_ROLE, "AIRDROP_ROLE");
        members2d[3] = appRoleMembers(app, Roles.CHARGE_ROLE, "CHARGE_ROLE");
        members2d[4] = appRoleMembers(app, Roles.TAKE_PROFIT_ROLE, "TAKE_PROFIT_ROLE");
    }

    function getUserAppInfo(address user, address app) public view returns (UserApp memory userApp){
        IApp iApp = IApp(app);
        (uint coins, uint airdrops) = IVipCoinDeposit(app).balanceOf(user);
        IERC20Metadata inner20 = IERC20Metadata(iApp.getVipCoin());
        ICardTracker tracker = ICardShopAccessor(IAppAccessor(app).cardShop()).tracker();
        ICardTracker.VipInfo memory vipInfo = tracker.getVipInfo(user);
        return UserApp(app, inner20.name(), inner20.symbol(),
            IAppAccessor(app).link(),
            IAppAccessor(app).paymentType(),
            vipInfo.name,
            vipInfo.expireAt,
            coins, airdrops, IVipCoinWithdraw(app).deferTimeSecs(),
            IVipCoinWithdraw(app).withdrawSchedules(user),
            IAppAccessor(app).cardShop()
        );
    }
    function listAppByUser(address user, uint256 offset, uint256 limit) public view returns (uint256 total, UserApp[] memory apps) {
        (uint total_, IAppRegistry.AppInfo[] memory list) = registry.listByUser(user, offset, limit);
        apps = new UserApp[](list.length);
        for(uint i=0; i<list.length; i++) {
            apps[i] = getUserAppInfo(user, list[i].addr);
        }
        return (total_, apps);
    }
}