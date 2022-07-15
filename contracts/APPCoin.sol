// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "./AppConfig.sol";

/** @dev Settlement contract between API consumer and API supplier.
 *
 * For Api supplier:
 * - setResourceWeightBatch
 * - setResourceWeight
 * - charge
 * - freeze
 * - takeProfit
 *
 * For api consumer:
 * - withdrawRequest
 * - forceWithdraw
 * - freeze
 */
contract APPCoin is ERC777, AppConfig, Pausable, Ownable, IERC777Recipient {
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    address public apiCoin;
    address public appOwner;
    modifier onlyAppOwner() {
        require(msg.sender == appOwner, 'not app owner');
        _;
    }
    // frozen; value 1 means frozen by manager;
    mapping(address=>uint256) public frozenMap;
    /** Total charged amount of each user.*/
    mapping(address=>uint256) public chargedMapping;
    /** Record all user who had been charged.*/
    address[] public users;
    struct UserCharged{
        address user;
        uint256 amount;
    }
    event Frozen(address indexed addr);
    /** Gap of seconds between withdrawRequest and forceWithdraw. */
    uint256 public forceWithdrawDelay;
    event Withdraw(address account, uint256 amount);
    uint256 public totalCharged;
    uint256 public totalTakenProfit;

    struct ChargeRequest {
        address account;
        uint256 amount;
        bytes data;
    }

    function tokensReceived(address /*operator*/, address from, address /*to*/, uint256 amount, bytes calldata /*userData*/, bytes calldata /*operatorData*/)
        override external whenNotPaused {
        require(msg.sender == apiCoin, 'ApiCoin Required');
        if (frozenMap[from] > 0) {
            revert('Account is frozen');
        }
        _mint(from, amount,'','');
    }
    // prevent transfer
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from == address(0) || to == address(0) || msg.sender == owner(), 'Not permitted');
        super._beforeTokenTransfer(operator, from, to, amount);
    }
    // -------- owner/bill manager operation -----------
    /**
    * @dev Freeze/Unfreeze an account.
    */
    function freeze(address acc, bool f) public {
        require(msg.sender == appOwner || msg.sender == owner(), 'Unauthorised');
        if (f) {
            frozenMap[acc] = 1;
            emit Frozen(acc);
        } else {
            delete frozenMap[acc];
        }
    }
    function takeProfit(address to, uint256 amount) public onlyAppOwner whenNotPaused {
        require(totalTakenProfit + amount <= totalCharged, "Amount exceeds");
        totalTakenProfit += amount;
        IERC777(apiCoin).send(to, amount, "takeProfit");
    }
    function chargeBatch(ChargeRequest[] memory requestArray) public onlyAppOwner whenNotPaused {
        for(uint i=0; i<requestArray.length; i++) {
            ChargeRequest memory request = requestArray[i];
            charge(request.account, request.amount, request.data);
        }
    }
    /** @dev Charge fee*/
    function charge(address account, uint256 amount, bytes memory data) public virtual onlyAppOwner whenNotPaused{
        _burn(account, amount, "", data);
        totalCharged += amount;
        if (chargedMapping[account] == 0 && amount > 0) {
            // record this account at the first time of charging.
            users.push(account);
        }
        chargedMapping[account] += amount;
        if (frozenMap[account] > 1) {
            // refund
            uint256 appCoinLeft = balanceOf(account);
            _burn(account, appCoinLeft, "", "refund");
            IERC777(apiCoin).send(account, appCoinLeft, "refund");
            delete frozenMap[account];
            emit Withdraw(account, appCoinLeft);
        }
    }
    // -------- api consumer operation -----------
    /**
    * @dev Not permitted.
    * @notice Prevent anyone from transferring app coin.
    */
    function burn(uint256 amount, bytes memory ) public override whenNotPaused{
        if(amount >= 0){
            revert('Not permitted');
        }
        super.burn(0, ""); // suppress warning
    }
    /** @dev Used by an API consumer to send a withdraw request, API key related to the caller will be frozen. */
    function withdrawRequest() public whenNotPaused {
        require(frozenMap[msg.sender] == 0, 'Account is frozen');
        frozenMap[msg.sender] = block.number;
        emit Frozen(msg.sender);
    }
    /** @dev After some time, user can force withdraw his funds anyway. */
    function forceWithdraw() public whenNotPaused {
        require(frozenMap[msg.sender] != 1, 'Frozen by admin');
        require(frozenMap[msg.sender] > 0, 'Withdraw request first');
        require(block.number - frozenMap[msg.sender] > forceWithdrawDelay, 'Waiting time');
        uint256 appCoinLeft = balanceOf(msg.sender);
        _burn(msg.sender, appCoinLeft, "force withdraw", "");
        IERC777(apiCoin).send(msg.sender, appCoinLeft, "force withdraw");
        delete frozenMap[msg.sender];
        emit Withdraw(msg.sender, appCoinLeft);
    }
    // -------- app owner operation -----------
    function setForceWithdrawDelay(uint256 delay) public onlyAppOwner whenNotPaused{
        require(delay <= 3600 * 3, 'delay exceeds 3 hours');
        forceWithdrawDelay = delay;
    }
    // ------------ public -------------
    function listUser(uint256 offset, uint256 limit) public view returns (UserCharged[] memory, uint256 total){
        require(offset <= users.length, 'invalid offset');
        if (offset + limit >= users.length) {
            limit = users.length - offset;
        }
        UserCharged [] memory arr = new UserCharged[](limit);
        for(uint i=0; i<limit; i++) {
            arr[i] = UserCharged(users[offset], chargedMapping[users[offset]]);
            offset += 1;
        }
        return (arr, users.length);
    }
    // -------------------------open zeppelin----------------------------
    constructor()
        ERC777("", "", new address[](0)) {
    }
    /**
     *  Called immediately after constructing through Controller contract.
     */
    function initOwner(address owner_) public {
        require(owner() == address(0), 'Owner exists');
        _transferOwnership(owner_);
    }
    function init(address apiCoin_, address appOwner_, string memory name_, string memory symbol_) public onlyOwner{
        require(apiCoin == address(0), 'Already initialized!');

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _name = name_;
        _symbol = symbol_;
        apiCoin = apiCoin_;
        appOwner = appOwner_;
        forceWithdrawDelay = 3600;
        nextConfigId = 1; // starts from 1, not zero
        ConfigRequest memory request = ConfigRequest(0, "default", 1, OP.ADD);
        _configResource(request);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeAppConfig() internal override onlyAppOwner {
        // nothing but a modifier to check permission
    }

    function balanceOfWithAirdrop(address owner) virtual view public returns (uint256 total, uint256 airdrop) {
        return (balanceOf(owner), 0);
    }
}