// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./AppCoinV2.sol";
import "./VipCoin.sol";
import "./ApiWeightToken.sol";

abstract contract AppCore is Initializable, AccessControlEnumerable {

    uint256 public constant TOKEN_ID_COIN = 0;

    AppCoinV2 public appCoin;
    VipCoin public vipCoin;
    ApiWeightToken public apiWeightToken;

    constructor() {
        _disableInitializers();
    }

    function __AppCore_init(AppCoinV2 appCoin_, VipCoin vipCoin_, ApiWeightToken apiWeightToken_, address owner) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);

        appCoin = appCoin_;
        vipCoin = vipCoin_;
        apiWeightToken = apiWeightToken_;
    }

}
