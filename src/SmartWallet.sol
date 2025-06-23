// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NotReallySmartWallet {
    function execute(address to, uint256 value, bytes calldata data) external payable {
        (bool success,) = to.call{value: value}(data);
        require(success, "Reverted");
    }
}
