// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/** Configuration functions for an App */
abstract contract AppConfig {
    event ResourceChanged(uint32 indexed id, uint32 indexed weight, OP indexed op);
    struct ConfigEntry {
        string resourceId;
        uint32 weight;
        uint32 index; // index in indexArray
    }
    /** auto-increment id, starts from 1 */
    uint32 public nextConfigId;
    /** store, key is auto-generated id */
    mapping(uint32=> ConfigEntry) public resourceConfigures;
    /** order of id. Deletion needs it. */
    uint32[] public indexArray;
    /** resourceId => id */
    mapping(string=>uint32) resources;

    /** Operation code for configuring resources, ADD 0; UPDATE: 1; DELETE: 2 */
    enum OP {ADD,UPDATE,DELETE}

    /** Operation code for configuring resources, ADD 0; UPDATE: 1; DELETE: 2 */
    struct ConfigRequest {
        uint32 id;
        string resourceId;
        uint32 weight;
        /** Operation code for configuring resources, ADD 0; UPDATE: 1; DELETE: 2 */
        OP op;
    }

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

    function configResource(ConfigRequest memory entry) public {
        _authorizeAppConfig();
        _configResource(entry);
    }
    function _configResource(ConfigRequest memory entry) internal {
        uint32 id = entry.id;
        string memory resourceId = entry.resourceId;
        uint32 weight = entry.weight;
        OP op = entry.op;
        if (op == OP.ADD) {
            // id starts from 1, if resourceId=>id > 0, it's added already.
            require(resources[resourceId] == 0, 'resource already added');
            require(id == 0, "id should be zero when adding");

            id = nextConfigId;
            nextConfigId += 1;

            resources[resourceId] = id;
            resourceConfigures[id] = ConfigEntry(resourceId, weight, uint32(indexArray.length));

            // track index.
            indexArray.push(id);
        } else if (op == OP.UPDATE) {
            require(id > 0, 'invalid id');
            require(resources[resourceId] == id, 'id/resourceId mismatch');
            resourceConfigures[id].weight = weight;
        } else if (op == OP.DELETE) {
            require(resources[resourceId] == id, 'resource id mismatch');
            require(id > 1, 'can not delete id 1');
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
            delete resources[resourceId];
            delete resourceConfigures[id];
        }
        emit ResourceChanged(id, weight, op);
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
            offset ++;
        }
        return (slice, total);
    }
}
