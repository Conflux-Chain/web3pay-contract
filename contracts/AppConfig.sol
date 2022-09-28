// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./v2/interfaces.sol";

/**
 * Configuration functions for an App.
 */
abstract contract AppConfig is IAppConfig{
    event ResourceChanged(uint32 indexed id, uint256 indexed weight, OP indexed op);
    event ResourcePending(uint32 indexed id, uint256 indexed newWeight, OP indexed op);

    /* token id for fungible token (ERC20, APP Coin) */
    uint256 public constant FT_ID = 0;
    uint256 public constant AIRDROP_ID = 1; // privilege
    uint256 public constant TAKE_PROFIT_ID = 2; // privilege
    uint256 public constant BILLING_ID = 3; // privilege
    uint256 public constant TOKEN_AIRDROP_ID = 4; // token
    /** reserve gap */
    uint32 public constant FIRST_CONFIG_ID = 1001;
    /** auto-increment id, starts from `FIRST_CONFIG_ID` */
    uint32 public nextConfigId;
    /** store, key is auto-generated id */
    mapping(uint32=> ConfigEntry) public resourceConfigures;
    /** order of id. Deletion needs it. */
    uint32[] public indexArray;
    /** resourceId => id */
    mapping(string=>uint32) resources;
    //----- pending -----
    uint32[] public pendingIdArray;
    mapping(uint32=>bool) pendingIdMap;
    uint256 public pendingSeconds;

    /** Operation code for configuring resources, ADD 0; UPDATE: 1; DELETE: 2 */
    struct ConfigRequest {
        uint32 id;
        string resourceId;
        uint256 weight;
        /** Operation code for configuring resources, ADD 0; UPDATE: 1; DELETE: 2 */
        OP op;
    }
    /* request counter per user, per resource id */
    mapping(address=>mapping(uint32=>uint256)) userRequestCounter;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;

    constructor(){
        // nothing
    }

    function _authorizeAppConfig() internal virtual;

    function configResourceBatch(ConfigRequest[] memory entries) public {
        _authorizeAppConfig();
        for(uint256 i=0; i<entries.length; i++) {
            ConfigRequest memory entry = entries[i];
            configResource(entry);
        }
    }

    /**
     * There is a delayed execution mechanism when configuring resources.
     */
    function configResource(ConfigRequest memory entry) public {
        _authorizeAppConfig();
        _configResource(entry);
    }
    function _configResource(ConfigRequest memory entry) internal {
        uint32 id = entry.id;
        // affects code size
//        string memory resourceId = entry.resourceId;
//        uint256 weight = entry.weight;
        OP op = entry.op;
        if (op == OP.ADD) {
            // id starts from `FIRST_CONFIG_ID`, if resourceId=>id > 0, it's added already.
            require(resources[entry.resourceId] == 0, 'dup'); //resource already added
            require(id == 0, "id != 0");//id should be zero when adding

            id = nextConfigId;
            nextConfigId += 1;

            resources[entry.resourceId] = id;
            resourceConfigures[id] = ConfigEntry(entry.resourceId, 0, uint32(indexArray.length), op, entry.weight, block.timestamp, 0);
            /*pending*/ //_mintConfig(address(this), id, weight, "add config");

            // track index.
            indexArray.push(id);
        } else if (op == OP.UPDATE) {
            // Only update weights are supported.
            require(id >= FIRST_CONFIG_ID, 'invalid id');
            require(resources[entry.resourceId] == id, 'neq');//id/resourceId mismatch
            setPendingProp(id, op, entry.weight);
        } else if (op == OP.DELETE) {
            require(resources[entry.resourceId] == id, 'neq');//resource id mismatch
            require(id > FIRST_CONFIG_ID, '403');//can not delete default entry
            if (resourceConfigures[id].pendingOP == OP.ADD) {
                resourceConfigures[id].pendingOP = OP.DELETE;
                // inactive entry, delete directly
                _flushPendingConfig(0);
                return;
            }
            setPendingProp(id, op, entry.weight);
            /*pending
            uint32 lastIdValue = indexArray[indexArray.length - 1];
            indexArray.pop();
            if (id == lastIdValue) {
                // just the last one
            } else {
                uint32 indexInArray = resourceConfigures[id].index;
                // move id at the end to current index
                indexArray[indexInArray] = lastIdValue;
                // update index for that entry
                resourceConfigures[lastIdValue].index = indexInArray;
            }
            _burnConfig(address(this), id, resourceConfigures[id].weight);
            delete resources[resourceId];
            delete resourceConfigures[id];
            */
        } else {
            revert("invalid operation");
        }
        if (!pendingIdMap[id]) {
            pendingIdMap[id] = true;
            pendingIdArray.push(id);
        }
        emit ResourcePending(id, entry.weight, op);
    }
    function setPendingProp(uint32 id, OP op_, uint256 weight_) internal {
        if (resourceConfigures[id].pendingOP == OP.ADD && op_ == OP.UPDATE) {
            op_ = OP.ADD;// keep adding if an entry is not active
        }
        resourceConfigures[id].pendingOP = op_;
        resourceConfigures[id].pendingWeight = weight_;
        resourceConfigures[id].submitSeconds = block.timestamp;
    }
    /** Make the configuration that satisfies the delay mechanism take effect.  */
    function flushPendingConfig() public {
        _flushPendingConfig(pendingSeconds);
    }
    function _flushPendingConfig(uint256 pendingSeconds_) internal {
        uint32[] memory newPendingArray;
        uint newIndex = 0;
        if (pendingIdArray.length == 0) {
            return;
        }
        for(uint i=pendingIdArray.length - 1; i >= 0; i--) {
            uint32 id = pendingIdArray[i];
            // clean it
            pendingIdArray.pop();
            ConfigEntry storage config = resourceConfigures[id];
            if (block.timestamp - config.submitSeconds < pendingSeconds_) {
                newPendingArray[newIndex++] = id;
                continue;
            }
            OP op = config.pendingOP;
            uint256 weight = config.pendingWeight;
            if (op == OP.ADD) {
                _mintConfig(address(this), id, weight, "add config");
                config.weight = config.pendingWeight;
            } else if (op == OP.UPDATE) {
                if (weight >= config.weight) {
                    _mintConfig(address(this), id, weight - resourceConfigures[id].weight, "update config");
                } else {
                    _burnConfig(address(this), id, resourceConfigures[id].weight - weight);
                }
                config.weight = config.pendingWeight;
            } else if (op == OP.DELETE) {
                uint32 lastIdValue = indexArray[indexArray.length - 1];
                indexArray.pop();
                if (id == lastIdValue) {
                    // just the last one
                } else {
                    uint32 indexInArray = resourceConfigures[id].index;
                    // move id at the end to current index
                    indexArray[indexInArray] = lastIdValue;
                    // update index for that entry
                    resourceConfigures[lastIdValue].index = indexInArray;
                }
                _burnConfig(address(this), id, resourceConfigures[id].weight);
                delete resources[config.resourceId];
                delete resourceConfigures[id];
            }
            emit ResourceChanged(id, weight, op);
            // cleanup
            config.pendingOP = OP.NO_PENDING;
            delete pendingIdMap[id];
            // keeps information
            //config.submitSeconds = 0;
            //config.pendingWeight = 0;
            if (i==0) {
                break;
            }
        }
        // set still pending ids
        for(uint i=0; i<newPendingArray.length; i++) {
            pendingIdArray.push(newPendingArray[i]);
        }
    }
    function listUserRequestCounter(address user, uint32[] memory ids) public view returns (uint256[] memory times) {
        times = new uint256[](ids.length);
        for(uint32 i=0; i<ids.length;i++) {
            times[i] = userRequestCounter[user][ids[i]];
        }
    }
    function listResources(uint256 offset, uint256 limit) public view returns(ConfigEntry[] memory, uint256 total) {
        total = indexArray.length;
        require(offset <= total, 'invalid offset');
        if (offset + limit >= total) {
            limit = total - offset;
        }
        ConfigEntry[] memory slice = new ConfigEntry[](limit);
        for(uint32 i=0; i<limit;i++) {
            uint32 id = indexArray[i];
            slice[i] = resourceConfigures[id];
            slice[i].index = resources[slice[i].resourceId]; // use index as id
            offset ++;
        }
        return (slice, total);
    }

    function _mintConfig(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
    }
    function _burnConfig(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
    }
}
