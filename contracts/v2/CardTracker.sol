// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Interfaces.sol";
contract CardTracker is ICardTracker{
    event VipChange(address indexed account, uint expireAt, uint16 level);
    address _eventSource;
    struct VipInfo {
        uint expireAt;
        uint8 level; // base 1
    }
    mapping(address=>VipInfo) _vipMap;
    constructor(address eventSource) {
        _eventSource = eventSource;
    }
    function track(address from, address to, ICard.Card memory pkg) external override {
        require(msg.sender == _eventSource, "401");
        if (from == address(0)) {
            // expand expire time
            VipInfo storage info = _vipMap[to];
            if (info.expireAt < block.timestamp) {
                info.expireAt = block.timestamp + pkg.duration;
                info.level = 1;
            } else {
                info.expireAt += pkg.duration;
            }
            emit VipChange(to, info.expireAt, info.level);
        } else {
            // vip card can not be transferred, by design.
            revert("403");
        }
    }
}
