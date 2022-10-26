// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces.sol";
import "./Constant.sol";

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
    function setOwner() public {
        require(owner == address(0), "already set");
        owner = owner;
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
            IVipCoinWithdraw(app).withdrawSchedules(user)
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