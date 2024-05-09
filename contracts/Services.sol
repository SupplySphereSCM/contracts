// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./libs/Counters.sol";

contract Services is Context, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct Service {
        uint256 id;
        string name;
        uint256 price;
        uint256 tax;
        uint256 quantity;
        uint256 volume;
        address owner;
    }

    EnumerableSet.UintSet serviceIds;
    mapping(uint256 => Service) public services;
    Counters.Counter public serviceIdCounter;

    function addService(
        string calldata name,
        uint256 price,
        uint256 tax,
        uint256 quantity,
        uint256 volume
    ) public returns (uint256) {
        serviceIdCounter.increment();
        uint256 id = serviceIdCounter.current();
        require(!serviceIds.contains(id), "Service already registered.");
        services[id] = Service({
            id: id,
            name: name,
            price: price,
            tax: tax,
            quantity: quantity,
            owner: msg.sender,
            volume: volume
        });
        serviceIds.add(id);
        return id;
    }

    function removeService(uint256 id) public {
        require(serviceIds.contains(id), "Material does not exist.");
        serviceIds.remove(id);
        delete services[id];
    }

    function getService(uint256 id) public view returns (Service memory) {
        require(serviceIds.contains(id), "Material does not exist.");
        return services[id];
    }

    // function totalServices() public view returns (uint256) {
    //     return serviceIds.length();
    // }

    // function getServiceAtIndex(
    //     uint256 index
    // ) public view returns (Service memory) {
    //     require(index < serviceIds.length(), "Index out of bounds.");
    //     uint256 id = serviceIds.at(index);
    //     return services[id];
    // }

    function getAllServices() public view returns (Service[] memory) {
        uint256 total = serviceIds.length();
        Service[] memory allServices = new Service[](total);
        for (uint256 i = 0; i < total; i++) {
            uint256 id = serviceIds.at(i);
            allServices[i] = services[id];
        }
        return allServices;
    }
}
