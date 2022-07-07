// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract APPCoin is Initializable, ERC777Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, IERC777Recipient {
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    address public apiCoin;
    address public appOwner;
    modifier onlyAppOwner() {
        require(msg.sender == appOwner, 'not app owner');
        _;
    }
    // resources
    event ResourceChanged(uint32 indexed index);
    struct WeightEntry {
        string resourceId;
        uint weight;
    }
    uint32 public nextWeightIndex;
    mapping(uint32=>WeightEntry) public resourceWeights;
    // frozen; value 1 means frozen by manager;
    mapping(address=>uint256) public frozenMap;
    event Frozen(address indexed addr);
    uint256 public forceWithdrawAfterBlock;

    function tokensReceived(address /*operator*/, address from, address /*to*/, uint256 amount, bytes calldata /*userData*/, bytes calldata /*operatorData*/)
        override external {
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
    function freeze(address acc, bool f) public {
        require(msg.sender == appOwner || msg.sender == owner(), 'Unauthorised');
        if (f) {
            frozenMap[acc] = 1;
            emit Frozen(acc);
        } else {
            delete frozenMap[acc];
        }
    }
    // -------- api consumer operation -----------
    function withdrawRequest() public {
        require(frozenMap[msg.sender] == 0, 'Account is frozen');
        frozenMap[msg.sender] = block.number;
        emit Frozen(msg.sender);
    }
    function forceWithdraw() public {
        require(frozenMap[msg.sender] != 1, 'Frozen by admin');
        require(frozenMap[msg.sender] > 0, 'Withdraw request first');
        require(block.number - frozenMap[msg.sender] > forceWithdrawAfterBlock, 'Waiting time');
        uint256 appCoinLeft = balanceOf(msg.sender);
        burn(appCoinLeft, "force withdraw");
        IERC777Upgradeable(apiCoin).send(msg.sender, appCoinLeft, "force withdraw");
        delete frozenMap[msg.sender];
    }
    // -------- app owner operation -----------
    function setResourceWeightBatch(uint32[] calldata indexArr, string[] calldata resourceIdArr, uint[] calldata weightArr) onlyOwner public {
        require(indexArr.length == resourceIdArr.length, 'length mismatch');
        require(indexArr.length == weightArr.length, 'length mismatch');
        for(uint256 i=0; i<indexArr.length; i++) {
            setResourceWeight(indexArr[i], resourceIdArr[i], weightArr[i]);
        }
    }
    function setResourceWeight(uint32 index, string calldata resourceId, uint weight) onlyAppOwner public {
        require(index <= nextWeightIndex, 'invalid index');
        if (index == nextWeightIndex) {
            nextWeightIndex += 1;
        }
        resourceWeights[index] = WeightEntry(resourceId, weight);
        emit ResourceChanged(index);
    }
    function setForceWithdrawAfterBlock(uint256 diff) public onlyAppOwner {
        forceWithdrawAfterBlock = diff;
    }
    // ------------ public -------------
    function listResources(uint32 offset, uint32 limit) public view returns(WeightEntry[] memory) {
        require(offset < nextWeightIndex, 'invalid offset');
        if (offset + limit >= nextWeightIndex) {
            limit = nextWeightIndex - offset;
        }
        WeightEntry[] memory slice = new WeightEntry[](limit);
        for(uint32 i=0; i<limit;i++) {
            slice[i] = resourceWeights[offset];
            offset ++;
        }
        return slice;
    }
    // -------------------------open zeppelin----------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address apiCoin_, address appOwner_, string memory name_, string memory symbol_) initializer public {
        address[] memory defaultOperators = new address[](0);
        __ERC777_init(name_, symbol_, defaultOperators);
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        apiCoin = apiCoin_;
        appOwner = appOwner_;
        forceWithdrawAfterBlock = 10_000;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}