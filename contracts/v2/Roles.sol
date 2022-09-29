// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Roles {
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    // role to configure resource weight
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");
}
