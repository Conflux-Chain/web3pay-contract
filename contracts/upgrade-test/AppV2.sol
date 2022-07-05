// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../APPCoin.sol";

contract AppV2 is APPCoin{
    function version() public pure returns (string memory) {
        return "App v2";
    }
}
