// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract AppConfig {
    // resources
    event ResourceChanged(uint32 indexed index, uint32 weight);
    struct WeightEntry {
        string resourceId;
        uint32 weight;
    }
    uint32 public nextWeightIndex;
    mapping(uint32=>WeightEntry) public resourceWeights;

    constructor(){
        // nothing
    }

    function _authorizeAppConfig() internal virtual;

    function setResourceWeightBatch(uint32[] calldata indexArr,
        string[] calldata resourceIdArr,
        uint32[] calldata weightArr) public {
        _authorizeAppConfig();
        require(indexArr.length == resourceIdArr.length, 'length mismatch');
        require(indexArr.length == weightArr.length, 'length mismatch');
        for(uint256 i=0; i<indexArr.length; i++) {
            setResourceWeight(indexArr[i], resourceIdArr[i], weightArr[i]);
        }
    }

    function setResourceWeight(uint32 index, string calldata resourceId, uint32 weight) public {
        _authorizeAppConfig();
        require(index <= nextWeightIndex, 'invalid index');
        if (index == nextWeightIndex) {
            nextWeightIndex += 1;
        }
        resourceWeights[index] = WeightEntry(resourceId, weight);
        emit ResourceChanged(index, weight);
    }

    function listResources(uint32 offset, uint32 limit) public view returns(WeightEntry[] memory) {
        require(offset <= nextWeightIndex, 'invalid offset');
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
}
