// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ContractA {
    address public owner; // slot 0

    function initialize() external {
        require(owner == address(0), "Already initialized");
        owner = msg.sender;
    }

    // ...
}

contract ContractB {
    uint256 public balance; // slot 0 - same slot as ContractA's owner!

    function getBalance() external view returns (uint256) {
        return balance;
    }

    // ...
}

contract ContractA_7201 {
    // @custom:storage-location erc7201:example.contractA
    struct ContractAStorage {
        address owner;
        uint256 nonce;
        // future variables can be added here
    }
    
    // keccak256(abi.encode(uint256(keccak256("example.contractA")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ContractAStorageLocation = 
        0xd01525294f88a57baa3c94c84cf5cf8d70d334377609d6aabd7ec7c9ce460d00;
    
    function _getContractAStorage() private pure returns (ContractAStorage storage $) {
        assembly {
            $.slot := ContractAStorageLocation
        }
    }
    
    function initialize() external {
        ContractAStorage storage $ = _getContractAStorage();
        require($.owner == address(0), "Already initialized");
        $.owner = msg.sender;
    }
    
    function owner() public view returns (address) {
        ContractAStorage storage $ = _getContractAStorage();
        return $.owner;
    }
}