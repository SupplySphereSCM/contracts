// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./libs/Counters.sol";

contract Products is Context, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct Product {
        uint256 id;
        string name;
        uint256 quantity;
        uint256 available;
        uint256 price;
        uint256 tax;
        address owner;
    }

    EnumerableSet.UintSet productIds;
    Counters.Counter public productIdCounter;
    mapping(uint256 => Product) public products;

    function addProduct(
        string calldata name,
        uint256 price,
        uint256 tax,
        uint256 quantity
    ) public returns (uint256) {
        productIdCounter.increment();
        uint256 id = productIdCounter.current();
        require(!productIds.contains(id), "Product already registered.");
        products[id] = Product({
            id: id,
            name: name,
            price: price,
            tax: tax,
            owner: msg.sender,
            quantity: quantity,
            available: quantity
        });
        productIds.add(id);
        return id;
    }

    function removeProduct(uint256 id) public {
        require(productIds.contains(id), "Material does not exist.");
        productIds.remove(id);
        delete products[id];
    }

    function getProduct(uint256 id) public view returns (Product memory) {
        require(productIds.contains(id), "Material does not exist.");
        return products[id];
    }

    // function totalProducts() public view returns (uint256) {
    //     return productIds.length();
    // }

    // function getProductAtIndex(
    //     uint256 index
    // ) public view returns (Product memory) {
    //     require(index < productIds.length(), "Index out of bounds.");
    //     uint256 id = productIds.at(index);
    //     return products[id];
    // }

    function getAllProducts() public view returns (Product[] memory) {
        uint256 total = productIds.length();
        Product[] memory allProducts = new Product[](total);
        for (uint256 i = 0; i < total; i++) {
            uint256 id = productIds.at(i);
            allProducts[i] = products[id];
        }
        return allProducts;
    }
}
