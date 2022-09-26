// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VipCoin.sol";

contract VipCoinFactory {

    event Created(address indexed addr, address indexed operator, address indexed owner);

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        address app
    ) public returns (address) {
        VipCoin vc = new VipCoin(name, symbol, uri);

        // grant all roles to owner
        vc.grantRole(vc.DEFAULT_ADMIN_ROLE(), owner);
        vc.grantRole(vc.MINTER_ROLE(), owner);
        vc.grantRole(vc.PAUSER_ROLE(), owner);
        vc.grantRole(vc.CONSUMER_ROLE(), owner);
        // grant roles to app
        vc.grantRole(vc.MINTER_ROLE(), app);
        vc.grantRole(vc.CONSUMER_ROLE(), app);

        // renounce all roles for this factory
        vc.renounceRole(vc.DEFAULT_ADMIN_ROLE(), address(this));
        vc.renounceRole(vc.MINTER_ROLE(), address(this));
        vc.renounceRole(vc.PAUSER_ROLE(), address(this));
        vc.renounceRole(vc.CONSUMER_ROLE(), address(this));

        emit Created(address(vc), msg.sender, owner);

        return address(vc);
    }

}
