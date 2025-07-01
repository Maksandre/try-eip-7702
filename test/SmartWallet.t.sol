// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SmartWallet, Call} from "../src/SmartWallet.sol";

contract SmartWalletTest is Test {
    address public ALICE_ADDRESS;
    uint256 public ALICE_PRIVATE_KEY;
    address public BOB_ADDRESS;

    // Test parameters
    uint256 constant INITIAL_ALICE_BALANCE = 10 ether;
    uint256 constant TRANSFER_AMOUNT = 1 ether;

    // The contract that Alice will delegate execution to.
    SmartWallet public delegationTarget;



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
            Call({
                to: BOB_ADDRESS,
                value: TRANSFER_AMOUNT,
                data: ""
            })
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
            Call({
                to: BOB_ADDRESS,
                value: TRANSFER_AMOUNT,
                data: ""
            })
        );
    }

    function testAliceHasOwnState() public initializeAliceWallet {
        // Wallet's owner now is zero address
        assertEq(delegationTarget.owner(), address(0));

        // Alice's EOA owner is now Alice
        assertEq(SmartWallet(ALICE_ADDRESS).owner(), ALICE_ADDRESS);
    }




}
