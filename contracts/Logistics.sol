// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./libs/Counters.sol";

contract Logistics is Context, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct Logistic {
        uint256 id;
        string name;
        address owner;
        uint256 price;
    }

    EnumerableSet.UintSet logisticsIds;
    mapping(uint256 => Logistic) public logistics;
    Counters.Counter public logisticsIdCounter;

    function addLogistics(
        string calldata name,
        uint256 price
    ) public returns (uint256) {
        logisticsIdCounter.increment();
        uint256 id = logisticsIdCounter.current();
        require(!logisticsIds.contains(id), "Material already registered.");
        logistics[id] = Logistic({
            id: id,
            name: name,
            owner: _msgSender(),
            price: price
        });
        logisticsIds.add(id);
        return id;
    }

    function removeLogistic(uint256 id) public {
        require(logisticsIds.contains(id), "Material does not exist.");
        logisticsIds.remove(id);
        delete logistics[id];
    }

    function getLogistic(uint256 id) public view returns (Logistic memory) {
        require(logisticsIds.contains(id), "Material does not exist.");
        return logistics[id];
    }

    // function totalLogistics() public view returns (uint256) {
    //     return logisticsIds.length();
    // }

    // function getLogisticlAtIndex(
    //     uint256 index
    // ) public view returns (Logistic memory) {
    //     require(index < logisticsIds.length(), "Index out of bounds.");
    //     uint256 id = logisticsIds.at(index);
    //     return logistics[id];
    // }

    function getAllLogistics() public view returns (Logistic[] memory) {
        uint256 total = logisticsIds.length();
        Logistic[] memory allLogistics = new Logistic[](total);
        for (uint256 i = 0; i < total; i++) {
            uint256 id = logisticsIds.at(i);
            allLogistics[i] = logistics[id];
        }
        return allLogistics;
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
