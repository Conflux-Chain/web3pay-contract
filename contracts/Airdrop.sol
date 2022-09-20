// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./APPCoin.sol";
/**
 * Use this contract to airdrop to user with some free quota.
 * When charging, airdrops are consumed prior to real deposited quota.
 */
contract Airdrop is APPCoin {

//    mapping(address=>uint256) drops;

    function airdropBatch(address[] memory to, uint256[] memory amount, string[] memory reason) public {
        require(to.length == amount.length && to.length == reason.length, "400");//invalid length
        require(balanceOf(msg.sender, AIRDROP_ID) == 1, "403");
        for(uint i=0; i<to.length; i++) {
            _mintConfig(to[i], TOKEN_AIRDROP_ID, amount[i], bytes(reason[i]));
            _addNewUser(to[i]);
            emit Drop(to[i], amount[i], reason[i]);
        }
    }
    /** Query user's balance, returns (total amount, airdrop amount) */
    function balanceOfWithAirdrop(address owner) public view override returns (uint256 total, uint256 airdrop_){
        airdrop_ = balanceOf(owner, TOKEN_AIRDROP_ID);
        total = balanceOf(owner, FT_ID) + airdrop_;
    }

}