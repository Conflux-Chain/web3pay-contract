// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./VipCoin.sol";

abstract contract AppCore is Initializable, AccessControlEnumerable {

    uint256 public constant TOKEN_ID_COIN = 0;

    IERC20 public appCoin;
    VipCoin public vipCoin;

    constructor() {
        _disableInitializers();
    }

    function __AppCore_init(IERC20 appCoin_, VipCoin vipCoin_, address owner) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);

        appCoin = appCoin_;
        vipCoin = vipCoin_;
    }

}
