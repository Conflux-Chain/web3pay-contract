// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Cards.sol";

//TODO access control
/** Track card mint, calculate vip info. */
contract CardTracker {
    event VipChanged(address indexed account, uint expireAt, uint16 level);
    //Contract that could call to this one.
    address _eventSource;
    struct VipInfo {
        uint expireAt;
        uint8 level; // starts from 1
    }
    mapping(address=>VipInfo) _vipMap;
    constructor(address eventSource) {
        _eventSource = eventSource;
    }

    //TODO add level logic.
    function applyCard(address from, address to, Cards.Card memory card) external {
        require(msg.sender == _eventSource, "unauthorised");
        require(from == address(0), "not supported");
        // expand expire time
        VipInfo storage info = _vipMap[to];
        if (info.expireAt < block.timestamp) {
            info.expireAt = block.timestamp + card.duration;
            info.level = 1;
        } else {
            info.expireAt += card.duration;
        }
        emit VipChanged(to, info.expireAt, info.level);
    }

    function getVipInfo(address account) public view returns (VipInfo memory) {
        return _vipMap[account];
    }
}
