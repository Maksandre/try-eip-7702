// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SmartWallet, Call} from "../src/SmartWallet.sol";
import {TestERC20} from "../src/TestERC20.sol";
import {TokenSpender} from "../src/TokenSpender.sol";

contract BatchTest is Test {
    address public ALICE_ADDRESS;
    uint256 public ALICE_PRIVATE_KEY;
    address public BOB_ADDRESS;

    // The contract that Alice will delegate execution to.
    SmartWallet public delegationTarget;
    
    // Test ERC20 token for batch execution test
    TestERC20 public testToken;
    
    // Token spender contract that requires approval
    TokenSpender public tokenSpender;

    function setUp() public {
        // Generate addresses and keys dynamically
        (ALICE_ADDRESS, ALICE_PRIVATE_KEY) = makeAddrAndKey("alice");
        BOB_ADDRESS = makeAddr("bob");

        // Alice EOA starts with no code
        assertEq(ALICE_ADDRESS.code, bytes(""));

        // Deploy the delegation contract
        vm.prank(ALICE_ADDRESS);
        delegationTarget = new SmartWallet();
        
        // Deploy test ERC20 token
        testToken = new TestERC20();
        
        // Deploy token spender contract
        tokenSpender = new TokenSpender();
    }

    modifier initializeAliceWallet() {
        vm.signAndAttachDelegation(address(delegationTarget), ALICE_PRIVATE_KEY);
        vm.prank(ALICE_ADDRESS);
        SmartWallet(ALICE_ADDRESS).initialize(ALICE_ADDRESS);
        _;
    }

    function testExecuteBatchERC20ApproveTransferFrom() public initializeAliceWallet {
        // Transfer some tokens to Alice's wallet
        testToken.transfer(ALICE_ADDRESS, 1000 * 10**18);
        
        // Verify Alice has tokens
        assertEq(testToken.balanceOf(ALICE_ADDRESS), 1000 * 10**18);
        
        // Create batch calls for approve and transferFrom
        Call[] memory calls = new Call[](2);
        
        // Call 1: Approve the TokenSpender contract to spend 500 tokens from Alice
        calls[0] = Call({
            to: address(testToken),
            value: 0,
            data: abi.encodeWithSignature(
                "approve(address,uint256)",
                address(tokenSpender),
                500 * 10**18
            )
        });
        
        // Call 2: Use the TokenSpender contract to transfer 300 tokens from Alice to Bob
        calls[1] = Call({
            to: address(tokenSpender),
            value: 0,
            data: abi.encodeWithSignature(
                "transferFromToken(address,address,address,uint256)",
                address(testToken),
                ALICE_ADDRESS,
                BOB_ADDRESS,
                300 * 10**18
            )
        });
        
        // Execute the batch
        vm.prank(ALICE_ADDRESS);
        SmartWallet(ALICE_ADDRESS).executeBatch(calls);
        
        // Verify the results
        // Bob should have 300 tokens
        assertEq(testToken.balanceOf(BOB_ADDRESS), 300 * 10**18);
        
        // Alice should have 700 tokens remaining (1000 - 300)
        assertEq(testToken.balanceOf(ALICE_ADDRESS), 700 * 10**18);
        
        // TokenSpender should have allowance of 200 tokens remaining (500 - 300)
        assertEq(testToken.allowance(ALICE_ADDRESS, address(tokenSpender)), 200 * 10**18);
    }
} 