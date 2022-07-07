// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../APICoin.sol";

contract ApiV2 is APICoin{
    function version() public pure returns (string memory){
        return "ApiV2";
    }
}
