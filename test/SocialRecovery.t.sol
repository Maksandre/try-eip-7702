// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SmartWallet, Call} from "../src/SmartWallet.sol";

contract SocialRecoveryTest is Test {
    SmartWallet public wallet;
    
    // Test addresses
    address public owner;
    address public newOwner;
    address public guardian1;
    address public guardian2;
    address public guardian3;
    
    // Private keys for signing
    uint256 public guardian1Key;
    uint256 public guardian2Key;
    uint256 public guardian3Key;
    
    // Recovery parameters
    uint256 public constant RECOVERY_THRESHOLD = 2;
    address[] public guardians;

    function setUp() public {
        // Generate addresses and keys
        (owner,) = makeAddrAndKey("owner");
        (newOwner,) = makeAddrAndKey("newOwner");
        (guardian1, guardian1Key) = makeAddrAndKey("guardian1");
        (guardian2, guardian2Key) = makeAddrAndKey("guardian2");
        (guardian3, guardian3Key) = makeAddrAndKey("guardian3");
        
        // Set up guardians array
        guardians = new address[](3);
        guardians[0] = guardian1;
        guardians[1] = guardian2;
        guardians[2] = guardian3;
        
        // Deploy and initialize wallet
        wallet = new SmartWallet();
        vm.prank(owner);
        wallet.initialize(owner);
        
        // Fund the wallet
        vm.deal(address(wallet), 10 ether);
        
        // Set up guardians and threshold
        vm.prank(owner);
        wallet.setGuardians(guardians);
        vm.prank(owner);
        wallet.setRecoveryThreshold(RECOVERY_THRESHOLD);
    }

    function testSocialRecovery() public {
        // Step 1: Verify initial setup
        assertEq(wallet.owner(), owner);
        assertEq(wallet.recoveryThreshold(), RECOVERY_THRESHOLD);
        
        address[] memory currentGuardians = wallet.getGuardians();
        assertEq(currentGuardians.length, 3);
        assertEq(currentGuardians[0], guardian1);
        assertEq(currentGuardians[1], guardian2);
        assertEq(currentGuardians[2], guardian3);
        
        assertTrue(wallet.isGuardian(guardian1));
        assertTrue(wallet.isGuardian(guardian2));
        assertTrue(wallet.isGuardian(guardian3));
        
        // Step 2: Create recovery message hash
        bytes32 messageHash = keccak256(abi.encodePacked("RECOVER", newOwner));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        
        // Step 3: Generate signatures from guardians
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(guardian1Key, ethSignedMessageHash);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(guardian2Key, ethSignedMessageHash);
        
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = abi.encodePacked(r1, s1, v1);
        signatures[1] = abi.encodePacked(r2, s2, v2);
        
        // Step 4: Execute recovery
        wallet.recover(newOwner, signatures);
        
        // Step 5: Verify recovery was successful
        assertEq(wallet.owner(), newOwner);
        
        // Step 6: Verify new owner can execute transactions
        address recipient = makeAddr("recipient");
        uint256 initialBalance = recipient.balance;
        
        vm.prank(newOwner);
        wallet.execute(Call({
            to: recipient,
            value: 1 ether,
            data: ""
        }));
        
        assertEq(recipient.balance, initialBalance + 1 ether);
    }
} 