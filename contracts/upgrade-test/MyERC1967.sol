// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/** Use this contract to flatten ERC1967Proxy, and then verify on scan. */
contract MyERC1967 is ERC1967Proxy{
    constructor (address impl, bytes memory _data) ERC1967Proxy(impl, _data) {
    }
    function _beforeFallback() internal override virtual {
        console.log("_implementation: %s , this %s", _implementation(), address(this));
    }
}
