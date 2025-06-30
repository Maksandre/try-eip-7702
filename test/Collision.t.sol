// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SmartWallet} from "../src/SmartWallet.sol";
import {ContractA, ContractB, ContractA_7201} from "../src/Collision.sol";

contract CollisionTest is Test {
    address public ALICE_ADDRESS;
    uint256 public ALICE_PRIVATE_KEY;

    // Contracts for redelegation test
    ContractA public contractA;
    ContractB public contractB;
    ContractA_7201 public contractA_7201;

    function setUp() public {
        // Generate addresses and keys dynamically
        (ALICE_ADDRESS, ALICE_PRIVATE_KEY) = makeAddrAndKey("alice");

        // Alice EOA starts with no code
        assertEq(ALICE_ADDRESS.code, bytes(""));

        // Deploy test contracts A and B
        contractA = new ContractA();
        contractB = new ContractB();
        contractA_7201 = new ContractA_7201();
    }

    function testRedelegationStorageSlotConflict() public {
        // Step 1: Delegate Alice to ContractA and initialize
        vm.signAndAttachDelegation(address(contractA), ALICE_PRIVATE_KEY);
        vm.prank(ALICE_ADDRESS);
        ContractA(ALICE_ADDRESS).initialize();

        // Verify Alice is the owner in ContractA
        assertEq(ContractA(ALICE_ADDRESS).owner(), ALICE_ADDRESS);

        // Step 2: Redelegate Alice to ContractB
        vm.signAndAttachDelegation(address(contractB), ALICE_PRIVATE_KEY);

        // Step 3: The critical issue - Alice's address is now interpreted as a huge balance!
        // Alice's address (20 bytes) is being read as a uint256, which creates a massive number
        uint256 interpretedBalance = ContractB(ALICE_ADDRESS).balance();
        
        // This should be a very large number since Alice's address is being interpreted as a uint256
        assertGt(interpretedBalance, 0);
        
        // The balance should be approximately Alice's address value
        // Alice's address as uint256 should be a very large number
        uint256 aliceAddressAsUint = uint256(uint160(ALICE_ADDRESS));
        assertEq(interpretedBalance, aliceAddressAsUint);
    }

    function testNoCollisionWithERC7201() public {
        // Step 1: Delegate Alice to contractA_7201 and initialize
        vm.signAndAttachDelegation(address(contractA_7201), ALICE_PRIVATE_KEY);
        vm.prank(ALICE_ADDRESS);
        ContractA_7201(ALICE_ADDRESS).initialize();

        // Verify Alice is the owner in contractA_7201
        assertEq(ContractA_7201(ALICE_ADDRESS).owner(), ALICE_ADDRESS);

        // Step 2: Redelegate Alice to ContractB
        vm.signAndAttachDelegation(address(contractB), ALICE_PRIVATE_KEY);

        // No issue because contractA_7201 storage was initialized with ERC7201
        assertEq(ContractB(ALICE_ADDRESS).balance(), 0);
    }
} 