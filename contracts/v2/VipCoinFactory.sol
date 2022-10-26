// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./VipCoin.sol";

contract VipCoinFactory {

    event Created(address indexed addr, address indexed operator, address indexed owner);

    address public template;
    address public owner;
    IMetaBuilder public metaBuilder;

    function setOwner(address to) public {
        require(owner == address(0), "already set");
        owner = to;
    }

    function createTemplate() public {
        require(owner == msg.sender, "not owner");
        template = address(new VipCoin("","",""));
    }

    function setMetaBuilder(IMetaBuilder builder) public {
        require(owner == msg.sender, "not owner");
        metaBuilder = builder;
    }

    function create(
        string memory name,
        string memory symbol,
        string memory /*uri*/,
        address owner_,
        address app
    ) public returns (address) {
        VipCoin vc = VipCoin(Clones.clone(template));
        vc.initialize(name, symbol, owner_, app, metaBuilder);

        emit Created(address(vc), msg.sender, owner_);

        return address(vc);
    }

}
