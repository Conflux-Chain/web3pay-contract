// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./APPCoin.sol";
/**
 * Use this contract to airdrop to user with some free quota.
 * When charging, airdrops are consumed prior to real deposited quota.
 */
contract Airdrop is APPCoin {

    mapping(address=>uint256) drops;

    event Spend(address indexed from, uint256 amount);
    event Drop(address indexed to, uint256 amount, string reason);
    /** AppOwner could airdrop to user. */
    function airdrop(address to, uint256 amount, string memory reason) public onlyAppOwner {
        drops[to] += amount;
        emit Drop(to, amount, reason);
    }

    function airdropBatch(address[] memory to, uint256[] memory amount, string[] memory reason) public onlyAppOwner {
        require(to.length == amount.length, "invalid length of amount");
        require(to.length == reason.length, "invalid length of reason");
        for(uint i=0; i<to.length; i++) {
            airdrop(to[i], amount[i], reason[i]);
        }
    }
    /** Query user's balance, returns (total amount, airdrop amount) */
    function balanceOfWithAirdrop(address owner) public view override returns (uint256 total, uint256 airdrop_){
        airdrop_ = drops[owner];
        total = balanceOf(owner, FT_ID) + airdrop_;
    }
    /**
     * Charge account's quota.
     * Will emit `Spend` event if airdrops are consumed.
     * Will always emit ERC20 `Transfer` event (even real quota consumed is zero).
     */
    function charge(address account, uint256 amount, bytes memory data) public override onlyAppOwner whenNotPaused{
        uint256 dropBalance = drops[account];
        uint256 spendDrop = 0;
        uint256 spendSuper = amount;
        if (dropBalance >= amount) {
            // all amount is covered by airdrop.
            spendDrop = amount;
            spendSuper = 0;
        } else if (dropBalance > 0){
            //  partial amount is covered by airdrop.
            spendDrop = dropBalance;
            spendSuper = amount - dropBalance;
        }

        if (spendDrop > 0) {
            drops[account] = dropBalance - spendDrop;
            emit Spend(account, spendDrop);
        }
        // even `spendSuper` is zero, this must be executed.
        // zero record could help tracking transfer transaction.
        super.charge(account, spendSuper, data);
    }
}