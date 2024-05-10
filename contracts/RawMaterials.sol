// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./libs/Counters.sol";

contract RawMaterials is Context, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct RawMaterial {
        uint256 id;
        string name;
        uint256 quantity;
        uint256 available;
        uint256 price;
        uint256 tax;
        address owner;
    }

    EnumerableSet.UintSet materialIds;
    mapping(uint256 => RawMaterial) public materials;
    Counters.Counter public materialIdCounter;

    function addRawMaterial(
        string calldata name,
        uint256 price,
        uint256 tax,
        uint256 quantity
    ) public returns (uint256) {
        materialIdCounter.increment();
        uint256 id = materialIdCounter.current();
        require(!materialIds.contains(id), "Material already registered.");
        materials[id] = RawMaterial({
            id: id,
            name: name,
            price: price,
            tax: tax,
            owner: _msgSender(),
            quantity: quantity,
            available: quantity
        });
        materialIds.add(id);
        return id;
    }

    function removeRawMaterial(uint256 id) public {
        require(materialIds.contains(id), "Material does not exist.");
        materialIds.remove(id);
        delete materials[id];
    }

    function getRawMaterial(
        uint256 id
    ) public view returns (RawMaterial memory) {
        require(materialIds.contains(id), "Material does not exist.");
        return materials[id];
    }

    // function totalRawMaterials() public view returns (uint256) {
    //     return materialIds.length();
    // }

    // function getRawMaterialAtIndex(
    //     uint256 index
    // ) public view returns (RawMaterial memory) {
    //     require(index < materialIds.length(), "Index out of bounds.");
    //     uint256 id = materialIds.at(index);
    //     return materials[id];
    // }

    function getAllRawMaterials() public view returns (RawMaterial[] memory) {
        uint256 total = materialIds.length();
        RawMaterial[] memory allRawMaterials = new RawMaterial[](total);
        for (uint256 i = 0; i < total; i++) {
            uint256 id = materialIds.at(i);
            allRawMaterials[i] = materials[id];
        }
        return allRawMaterials;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        return tx.origin;
    }
}
