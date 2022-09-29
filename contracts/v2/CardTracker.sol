// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces.sol";

/** Track card mint, calculate vip info. */
contract CardTracker is ICardTracker{
    event VipChanged(address indexed account, uint expireAt, uint16 level);
    //Contract that could call to this one.
    address _eventSource;

    mapping(address=>VipInfo) _vipMap;
    constructor(address eventSource) {
        initialize(eventSource);
    }
    function initialize(address eventSource) public {
        require(_eventSource == address(0), "already initialized");
        _eventSource = eventSource;
    }

    //TODO add level logic.
    function applyCard(address from, address to, ICards.Card memory card) external override {
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

    function getVipInfo(address account) public override view returns (VipInfo memory) {
        return _vipMap[account];
    }
}
