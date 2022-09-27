// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TokenNameSymbol {
    string internal _name;
    string internal _symbol;

    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
}
