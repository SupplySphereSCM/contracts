// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract INR is ERC20, ERC20Permit {
    constructor() ERC20("Indian Rupee", "INR") ERC20Permit("Indian Rupee") {}

    function mint(address account, uint256 value) public {
        _mint(account, value);
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function burn(address account, uint256 value) public {
        _burn(account, value);
    }
}
