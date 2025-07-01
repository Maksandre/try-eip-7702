// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-contracts/token/ERC20/IERC20.sol";

contract TokenSpender {
    function transferFromToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        return IERC20(token).transferFrom(from, to, amount);
    }
} 