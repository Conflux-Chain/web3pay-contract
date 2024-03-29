// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./AppConfig.sol";
import "./IAPPCoin.sol";

/** @dev Settlement contract between API consumer and API supplier.
 *
 * For Api provider:
 * - setResourceWeightBatch
 * - setResourceWeight
 * - charge
 * - refund
 * - takeProfit
 *
 * For api consumer:
 * - withdrawRequest
 * - forceWithdraw
 */
contract APPCoin is ERC1155, AppConfig, Pausable, Ownable, IERC777Recipient, IERC1155Receiver {
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    address public apiCoin;
    address public appOwner;
    event AppOwnerChanged(address indexed to);
    event Spend(address indexed from, uint256 amount);//airdrop
    event Drop(address indexed to, uint256 amount, string reason);//airdrop
    string public name;
    string public symbol;
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
    uint256 public totalRequests;
    // all user who had deposited or been airdropped, value is block second
    mapping(address=>uint256) public allUserMapping;
    address[] public allUserArray;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[37] private __gap;

    function tokensReceived(address /*operator*/, address from, address /*to*/, uint256 amount, bytes calldata /*userData*/, bytes calldata /*operatorData*/)
        override external whenNotPaused {
        require(msg.sender == apiCoin, 'ApiCoin Required');//ApiCoin Required
        if (frozenMap[from] > 0) {
            revert('Frozen');
        }
        _mint(from, FT_ID, amount, 'deposit');
        _addNewUser(from);
    }
    function _addNewUser(address addr) internal {
        if (allUserMapping[addr] > 0) {
            return;
        }
        allUserMapping[addr] = block.timestamp;
        allUserArray.push(addr);
    }
    // prevent transfer
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(from == address(0) || to == address(0) || msg.sender == owner(), '403');
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    // -------- owner/bill manager operation -----------
    /**
    * @dev Freeze/Unfreeze an account.
    */
    function transferAppOwner(address to, address controller) public onlyAppOwner {
        IController(controller).changeAppOwner(appOwner, to);
        appOwner = to;
        emit AppOwnerChanged(to);
    }
    function freeze(address acc, bool f) public {
        require(msg.sender == appOwner || msg.sender == owner(), '403');
        if (f) {
            frozenMap[acc] = 1;
            emit Frozen(acc);
        } else {
            delete frozenMap[acc];
        }
    }

    function configPrivilege(address account, bool add, uint id) external onlyAppOwner  {
        uint mark = balanceOf(account, id);
        if (add) {
            require(mark == 0, "dup");//already added
            _mint(account, id, 1, 'configPrivilege');
        } else {
            require(mark == 1, "bad mark value");
            _burn(account, id, mark);
        }
    }
    function takeProfit(address to, uint256 amount) public whenNotPaused {
        require(balanceOf(msg.sender, TAKE_PROFIT_ID) == 1, "403");//check permission
        require(totalTakenProfit + amount <= totalCharged, "Amount exceeds");
        totalTakenProfit += amount;
//        IERC777(apiCoin).send(to, amount, "takeProfit");
        _swapApiCoin(amount, to);
    }
    function chargeBatch(ChargeRequest[] memory requestArray) public whenNotPaused {
        require(balanceOf(msg.sender, BILLING_ID) == 1, "403");//check permission
        for(uint i=0; i<requestArray.length; i++) {
            ChargeRequest memory request = requestArray[i];
            _charge(request.account, request.amount, request.data, request.useDetail);
        }
    }
    /**
     * Charge account's quota.
     * Will emit `Spend` event if airdrops are consumed.
     * Will always emit ERC20 `Transfer` event (even real quota consumed is zero).
     */
    function charge(address account, uint256 amount, bytes memory /*data*/, ResourceUseDetail[] memory useDetail) public virtual whenNotPaused{
        require(balanceOf(msg.sender, TAKE_PROFIT_ID) == 1, "403");//check permission
        // consume airdrop
        uint256 spendDrop = 0;
        uint256 spendSuper = amount;
        uint256 airdrop = balanceOf(account, TOKEN_AIRDROP_ID);
        if (airdrop >= amount) {
            // all amount is covered by airdrop.
            spendDrop = amount;
            spendSuper = 0;
        } else if (airdrop > 0){
            //  partial amount is covered by airdrop.
            spendDrop = airdrop;
            spendSuper = amount - airdrop;
        }

        if (spendDrop > 0) {
            _burnConfig(account, TOKEN_AIRDROP_ID, spendDrop);
            emit Spend(account, spendDrop);
        }
        _charge(account, spendSuper, "", useDetail);
    }
    /* charge without checking billing permission. **/
    function _charge(address account, uint256 amount, bytes memory /*data*/, ResourceUseDetail[] memory useDetail) internal virtual whenNotPaused{
        _burn(account, FT_ID, amount);
        totalCharged += amount;
        if (chargedMapping[account] == 0 && amount > 0) {
            // record this account at the first time of charging.
            users.push(account);
        }
        chargedMapping[account] += amount;

        for(uint i=0; i<useDetail.length; i++) {
            uint32 id = useDetail[i].id;
            ConfigEntry storage config = resourceConfigures[id];
            if (indexArray[config.index] == 0) {
                // id is zero, indicates this config doesn't exist
                continue;
            }
            config.requestTimes += useDetail[i].times;
            userRequestCounter[account][id] += useDetail[i].times;
            totalRequests += useDetail[i].times;
        }

        if (frozenMap[account] > 1) {
            // refund
            _withdraw(account, "refund");
        }
    }
    // -------- api consumer operation -----------
    /** @dev Used by an API consumer to send a withdraw request, API key related to the caller will be frozen. */
    function withdrawRequest() public whenNotPaused {
        require(frozenMap[msg.sender] == 0, 'Frozen');
        frozenMap[msg.sender] = block.timestamp;
        emit Frozen(msg.sender);
    }
    /** @dev After the delay time expires, the user can withdraw the remaining funds. */
    function forceWithdraw() public whenNotPaused {
        require(frozenMap[msg.sender] != 1, 'Frozen');
        require(frozenMap[msg.sender] > 0, 'WRF');//Withdraw request first
        require(block.timestamp - frozenMap[msg.sender] > forceWithdrawDelay, 'Waiting time');
        _withdraw(msg.sender, "force");
    }
    function refund(address account) public {
        // airdropping and refunding are some issues.
        require(balanceOf(msg.sender, AIRDROP_ID) == 1, "403");//check permission
        _withdraw(account, "refund");
    }
    function _withdraw(address account, bytes memory reason) internal {
        uint256 appCoinLeft = balanceOf(account, FT_ID);
        _burn(account, FT_ID, appCoinLeft);
        if (IAPICoin(apiCoin).baseToken() == address(0)) {
            IERC777(apiCoin).send(account, appCoinLeft, reason);
        } else {
            _swapApiCoin(appCoinLeft, account);
        }
        delete frozenMap[account];
        emit Withdraw(account, appCoinLeft);
    }
    function _swapApiCoin(uint amount, address to) internal {
        address[] memory path = new address[](1);
        path[0] = IAPICoin(apiCoin).baseToken(); // will be treated as with base token
        IAPICoin(apiCoin).withdraw(
            IAPICoin(apiCoin).swap_(),
                amount, amount, path, to, block.timestamp + 100);
    }
    // -------- app owner operation -----------
    function setForceWithdrawDelay(uint256 delay) public onlyAppOwner whenNotPaused{
        require(delay <= 3600 * 3, 'exceeds 3 hours');
        forceWithdrawDelay = delay;
    }
    // ------------ public -------------
    function listUser(uint256 offset, uint256 limit) public view returns (UserCharged[] memory, uint256 total){
        require(offset <= allUserArray.length);
        if (offset + limit >= allUserArray.length) {
            limit = allUserArray.length - offset;
        }
        UserCharged [] memory arr = new UserCharged[](limit);
        for(uint i=0; i<limit; i++) {
            arr[i] = UserCharged(allUserArray[offset], chargedMapping[allUserArray[offset]]);
            offset += 1;
        }
        return (arr, allUserArray.length);
    }
    // -------------------------open zeppelin----------------------------
    constructor()
        ERC1155("") {
    }
    /**
     *  Called immediately after constructing through Controller contract.
     */
    function initOwner(address owner_) public {
        require(owner() == address(0), 'dup');//Owner exists
        _transferOwnership(owner_);
    }
    function init(address apiCoin_, address appOwner_, string memory name_, string memory symbol_, string memory uri_, uint256 defaultWeight) public onlyOwner{
        require(apiCoin == address(0), 'dup');//Already initialized!

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        name = name_;
        symbol = symbol_;
        _setURI(uri_);
        apiCoin = apiCoin_;
        _mint(appOwner_, TAKE_PROFIT_ID, 1, "");
        _mint(appOwner_, AIRDROP_ID, 1, "");
        _mint(appOwner_, BILLING_ID, 1, "");
        appOwner = appOwner_;
        emit AppOwnerChanged(appOwner_);
        forceWithdrawDelay = 3600;
        pendingSeconds = 3600 * 24 * 7;
        nextConfigId = FIRST_CONFIG_ID;
        ConfigRequest memory request = ConfigRequest(0, "default", defaultWeight, OP.ADD);
        _configResource(request);
        _flushPendingConfig(0);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeAppConfig() internal view override {
        require(balanceOf(msg.sender, BILLING_ID) == 1, "403");//check permission
    }

    function balanceOfWithAirdrop(address owner) virtual view public returns (uint256 total, uint256 airdrop) {
        return (balanceOf(owner, FT_ID), 0);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
        return
        interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155MetadataURI).interfaceId ||
        interfaceId == type(IERC1155Receiver).interfaceId ||
        super.supportsInterface(interfaceId);
    }
    function onERC1155Received(
        address,// operator,
        address,// from,
        uint256,// id,
        uint256,// value,
        bytes calldata// data
    ) external override pure returns (bytes4){
        return 0xf23a6e61;
    }
    function onERC1155BatchReceived(
        address,// operator,
        address,// from,
        uint256[] calldata,// ids,
        uint256[] calldata,// values,
        bytes calldata// data
    ) external override pure returns (bytes4) {
        return 0xbc197c81;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory _name;
        if (tokenId == FT_ID) {
            _name = name;
        } else if (tokenId == TAKE_PROFIT_ID) {
            _name = "Payee";
        } else if (tokenId == BILLING_ID) {
            _name = "Billing";
        } else if (tokenId == AIRDROP_ID) {
            _name = "Operator";
        } else if (tokenId == TOKEN_AIRDROP_ID) {
            _name = "Voucher";
        } else {
            _name = resourceConfigures[uint32(tokenId)].resourceId;
        }
        string memory _desc = super.uri(tokenId);
        string memory json;
        string memory output;
        json = Base64.encode(bytes(string(abi.encodePacked("{\"name\":\"",_name,"\",\"image\":\"/favicon.ico\",\"description\":\"",_desc,"\"}"))));
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function _mintConfig(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override virtual {
        _mint(to,id,amount, data);
    }
    function _burnConfig(
        address from,
        uint256 id,
        uint256 amount
    ) internal override virtual {
        _burn(from,id,amount);
    }

    /**
     * In order to facilitate debugging, a delayed effective time interval can be set.
     * It is required that the name of this contract is DO_NOT_DEPOSIT and the symbol is ALL_YOU_FUNDS_WILL_LOST.
     */
    function setPendingSeconds(uint seconds_) public {
        require(hashCompareWithLengthCheck(name, "DO_NOT_DEPOSIT"), "403");
        require(hashCompareWithLengthCheck(symbol, "ALL_YOU_FUNDS_WILL_LOST"), "403.");
        pendingSeconds = seconds_;
    }

    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
}