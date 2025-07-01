// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Call {
    address to;
    uint256 value;
    bytes data;
}

contract SmartWallet {
    address public owner;
    
    // Social recovery variables
    address[] public guardians;
    uint256 public recoveryThreshold;
    mapping(address => bool) public isGuardian;

    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    function execute(Call calldata call) external payable onlyOwner {
        (bool success,) = call.to.call{value: call.value}(call.data);
        require(success, "Reverted");
    }

    function executeBatch(Call[] calldata calls) external payable onlyOwner {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success,) = calls[i].to.call{value: calls[i].value}(calls[i].data);
            require(success, "Batch transaction reverted");
        }
    }

    // Social recovery functions
    
    function setGuardians(address[] calldata _guardians) external onlyOwner {
        // Clear existing guardians
        for (uint256 i = 0; i < guardians.length; i++) {
            isGuardian[guardians[i]] = false;
        }
        
        // Set new guardians
        guardians = _guardians;
        for (uint256 i = 0; i < guardians.length; i++) {
            require(guardians[i] != address(0), "Invalid guardian");
            isGuardian[guardians[i]] = true;
        }
    }
    
    function setRecoveryThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0 && _threshold <= guardians.length, "Invalid threshold");
        recoveryThreshold = _threshold;
    }
    
    function recover(address newOwner, bytes[] calldata signatures) external {
        require(guardians.length > 0, "No guardians set");
        require(recoveryThreshold > 0, "No threshold set");
        require(signatures.length >= recoveryThreshold, "Insufficient signatures");
        require(newOwner != address(0), "Invalid new owner");
        
        // Verify signatures from guardians
        uint256 validSignatures = 0;
        bytes32 messageHash = keccak256(abi.encodePacked("RECOVER", newOwner));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = recoverSigner(ethSignedMessageHash, signatures[i]);
            if (isGuardian[signer]) {
                validSignatures++;
            }
        }
        
        require(validSignatures >= recoveryThreshold, "Insufficient valid signatures");
        
        // Change owner
        owner = newOwner;
    }
    
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) v += 27;
        require(v == 27 || v == 28, "Invalid signature 'v' value");
        
        return ecrecover(ethSignedMessageHash, v, r, s);
    }
    
    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }
}
