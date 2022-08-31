// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IAPPCoin.sol";
import "./TokenRouter.sol";
/** @dev API coin is the currency in the whole payment service.
 *
 * For api consumer:
 * - depositToApp
 * - refund
 *
 * For api supplier:
 * - refund
 *
 */
contract APICoin is TokenRouter, Initializable, ERC777Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /** user address => appArray ever deposited to */
    mapping(address=>address[]) userPaidAppArray;
    /** user address => (app address=> total deposit amount) */
    mapping(address=>mapping(address=>uint256)) userPaidAppMap;
    /** @dev Used by API consumer to deposit for specified app.
     *
     * For now it only takes CFX, and 1 CFX exchanges 1 APP Coin.
     *
     * API supplier may set `price/weight` for each API, so, how many requests could be made depends on both the deposited funds and
     * the `price/weight` of consumed API.
     *
     * Parameter `appCoin` is the settlement contract of the app, please contact API supplier to get it.
     */
    function depositToApp(address appCoin) public payable whenNotPaused {
        require(baseToken == address(0), "use token router instead");
        uint amount = msg.value;
        require(amount > 0, 'Zero value');
        _mintAndSend(amount, appCoin);
    }
    function _mintAndSend(uint amount, address appCoin) internal override {
        require(IAPPCoin(appCoin).apiCoin() == address(this), 'Invalid app');
        _mint(msg.sender, amount, '','');
        if (userPaidAppMap[msg.sender][appCoin] > 0) {
            userPaidAppMap[msg.sender][appCoin] += amount;
        } else {
            userPaidAppMap[msg.sender][appCoin] = amount;
            userPaidAppArray[msg.sender].push(appCoin);
        }
        send(appCoin, amount, "");
    }
    function listPaidApp(address user_, uint offset, uint limit) public view returns (address[] memory apps, uint total) {
        address[] memory paidArray = userPaidAppArray[user_];
        if (offset == 0 && limit >= paidArray.length) {
            return (paidArray, paidArray.length);
        }
        require(offset <= paidArray.length, 'invalid offset');
        if (offset + limit >= paidArray.length) {
            limit = paidArray.length - offset;
        }
        address [] memory arr = new address[](limit);
        for(uint i=0; i<limit; i++) {
            arr[i] = paidArray[offset];
            offset += 1;
        }
        return (arr, paidArray.length);
    }
    /** @dev Used by anyone who holds API coin to exchange CFX back. */
    function refund(uint256 amount) public whenNotPaused {
        require(baseToken == address(0), "use token router instead");
        _burnInner(amount, "refund");
        payable(msg.sender).transfer(amount);
    }
    function _burnInner(uint amount, bytes memory data) internal override {
        super.burn(amount, data);
    }
    //----------------------- OpenZeppelin code --------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, address baseToken, address[] calldata defaultOperators) initializer public {
        __ERC777_init(name_, symbol_, defaultOperators);
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        initTokenRouter(baseToken);
    }

    function setSwap(address _swap) override public onlyOwner{
        super.setSwap(_swap);
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