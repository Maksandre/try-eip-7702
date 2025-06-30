// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SmartWallet} from "../src/SmartWallet.sol";
import {ContractA, ContractB, ContractA_7201} from "../src/Collision.sol";

contract SmartWalletTest is Test {
    address public ALICE_ADDRESS;
    uint256 public ALICE_PRIVATE_KEY;
    address public BOB_ADDRESS;

    // Test parameters
    uint256 constant INITIAL_ALICE_BALANCE = 10 ether;
    uint256 constant TRANSFER_AMOUNT = 1 ether;

    // The contract that Alice will delegate execution to.
    SmartWallet public delegationTarget;

    // Contracts for redelegation test
    ContractA public contractA;
    ContractB public contractB;
    ContractA_7201 public contractA_7201;

    function setUp() public {
        // Generate addresses and keys dynamically
        (ALICE_ADDRESS, ALICE_PRIVATE_KEY) = makeAddrAndKey("alice");
        BOB_ADDRESS = makeAddr("bob");

        // Alice EOA starts with no code
        assertEq(ALICE_ADDRESS.code, bytes(""));

        // Bob starts with no balance
        assertEq(BOB_ADDRESS.balance, 0 ether);

        // Fund Alice's account
        vm.deal(ALICE_ADDRESS, INITIAL_ALICE_BALANCE);

        // Deploy the delegation contract
        vm.prank(ALICE_ADDRESS);
        delegationTarget = new SmartWallet();

        // Deploy test contracts A and B
        contractA = new ContractA();
        contractB = new ContractB();
        contractA_7201 = new ContractA_7201();
    }

    modifier initializeAliceWallet() {
        vm.signAndAttachDelegation(address(delegationTarget), ALICE_PRIVATE_KEY);
        vm.prank(ALICE_ADDRESS);
        SmartWallet(ALICE_ADDRESS).initialize(ALICE_ADDRESS);
        _;
    }

    function testDelegationWorks() public initializeAliceWallet {
        // Alice's code is a delegation designator
        assertEq(
            ALICE_ADDRESS.code,
            abi.encodePacked(hex"ef0100", address(delegationTarget))
        );

        // Alice calls her own EOA address as if it were a smart contract wallet
        vm.prank(ALICE_ADDRESS);
        SmartWallet(ALICE_ADDRESS).execute(
            BOB_ADDRESS,
            TRANSFER_AMOUNT,
            ""
        );

        // Verify final balances
        assertEq(BOB_ADDRESS.balance, TRANSFER_AMOUNT);
        assertEq(
            ALICE_ADDRESS.balance,
            INITIAL_ALICE_BALANCE - TRANSFER_AMOUNT
        );
    }

    function testBobCannotExecuteAliceWallet() public initializeAliceWallet {
        // Bob cannot execute Alice's wallet
        vm.prank(BOB_ADDRESS);
        vm.expectRevert("Unauthorized");
        SmartWallet(ALICE_ADDRESS).execute(
            BOB_ADDRESS,
            TRANSFER_AMOUNT,
            ""  
        );
    }

    function testAliceHasOwnState() public initializeAliceWallet {
        // Wallet's owner now is zero address
        assertEq(delegationTarget.owner(), address(0));

        // Alice's EOA owner is now Alice
        assertEq(SmartWallet(ALICE_ADDRESS).owner(), ALICE_ADDRESS);
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
