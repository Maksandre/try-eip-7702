// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
} 