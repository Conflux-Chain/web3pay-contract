// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Use this contract to flatten ERC1967Proxy, and then verify on scan.
contract MyERC1967 is ERC1967Proxy{
    constructor (address impl) ERC1967Proxy(impl, "") {

    }
}
