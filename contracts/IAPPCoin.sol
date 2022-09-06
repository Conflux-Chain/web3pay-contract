// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAPPCoin {
    function apiCoin() external returns (address);
}
interface IAPICoin {
    function baseToken() external returns (address);
    function swap_() external returns (address);
    function withdraw(address swap,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

interface IController {
    function changeAppOwner(address from, address to) external;
}