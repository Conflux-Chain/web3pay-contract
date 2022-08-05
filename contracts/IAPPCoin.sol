// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAPPCoin {
    function apiCoin() external returns (address);
}

interface IController {
    function changeAppOwner(address from, address to) external;
}