// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./VipCoin.sol";

contract AppCore {

    IERC20 public appCoin;
    VipCoin public vipCoin;

    /**
     * @dev For initialization in proxy constructor.
     */
    function initialize(IERC20 appCoin_, VipCoin vipCoin_) public {
        require(address(appCoin) == address(0), "App: already initialized");

        appCoin = appCoin_;
        vipCoin = vipCoin_;
    }

}
