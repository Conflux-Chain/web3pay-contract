// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces.sol";

/** Track card mint, calculate vip info. */
contract CardTracker is ICardTracker{
    event VipChanged(address indexed account, uint expireAt);
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

    // There is no upgrade logic for now, just override props and extend the expiration time.
    function applyCard(address from, address to, ICards.Card memory card) external override {
        require(msg.sender == _eventSource, "unauthorised");

        require(from == address(0), "not supported");
        // expand expire time
        VipInfo storage info = _vipMap[to];
        if (info.expireAt < block.timestamp) {
            info.expireAt = block.timestamp + card.duration;
        } else {
            info.expireAt += card.duration;
        }
        // 311040000 =  3600 * 24 * 30 * 12 * 10, ten years
        require(info.expireAt - block.timestamp < 311040000, "Expiration time exceeded");
        // override props
        info.props = card.template.props;
        info.name = card.template.name;
        emit VipChanged(to, info.expireAt);
    }

    function getVipInfo(address account) public override view returns (VipInfo memory) {
        return _vipMap[account];
    }
}
