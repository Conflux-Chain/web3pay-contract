// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./VipCoin.sol";

contract VipCoinFactory {

    event Created(address indexed addr, address indexed operator, address indexed owner);

    address public template;
    function createTemplate() public {
        require(template == address(0), "already created");
        template = address(new VipCoin("","",""));
    }

    function create(
        string memory name,
        string memory symbol,
        string memory /*uri*/,
        address owner,
        address app
    ) public returns (address) {
        VipCoin vc = VipCoin(Clones.clone(template));
        vc.initialize(name, symbol, owner, app);

        emit Created(address(vc), msg.sender, owner);

        return address(vc);
    }

}
