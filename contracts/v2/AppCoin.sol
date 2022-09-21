// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * @dev App Coin is used for web3 payment for all applications.
 */
contract AppCoin is ERC4626 {

    // Generally, the `asset` is a stable coin, e.g. USDT
    constructor(IERC20Metadata asset) ERC20("App Coin", "AC") ERC4626(asset) {
        require(asset.decimals() == 18, "Asset decimals requires 18");
    }

}
