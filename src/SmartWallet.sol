// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SmartWallet {
    address public owner;

    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyOwner {
        (bool success,) = to.call{value: value}(data);
        require(success, "Reverted");
    }
}
