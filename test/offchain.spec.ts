import { describe, it, expect } from "vitest";
import { privateKeyToAccount } from "viem/accounts";
import { getConfig } from "./helpers";
import { encodeFunctionData, zeroAddress } from "viem";

// NOTE: You need to run anvil (anvil --hardfork prague)
// it requires restarting anvil after each test

// Anvil account private keys
const ACCOUNT_2_PRIVATE_KEY = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const ACCOUNT_3_PRIVATE_KEY = "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";

describe("SmartWallet EIP-7702 Authorization", () => {
  it("should deploy implementation and authorize for EOAs using SET_CODE_TX_TYPE", async () => {
    const { client, account: executor, walletClient, implementationAddress, artifact } = await getConfig();
    
    // Create accounts for authorization
    const delegator = privateKeyToAccount(ACCOUNT_2_PRIVATE_KEY);
    
    // Get account addresses
    const delegatorAddress = delegator.address;
    
    const authorization = await walletClient.signAuthorization({
      contractAddress: implementationAddress,
      account: delegator,
      executor,
    });
    
    // Send EIP-7702 transaction for account 2 with authorization and initialization
    const authTx = await walletClient.sendTransaction({
      account: executor,
      to: delegatorAddress,
      data: encodeFunctionData({
        abi: artifact.abi,
        functionName: "initialize",
        args: [delegator.address],
      }),
      type: "eip7702",
      authorizationList: [authorization],
    });
    
    // Wait for authorization transaction
    const authReceipt2 = await client.waitForTransactionReceipt({ hash: authTx });
    expect(authReceipt2.status).toBe("success");

    const code = await client.getCode({
      address: delegatorAddress,
    });

    expect(code).not.toBe(undefined);

    const owner = await client.readContract({
      address: delegatorAddress,
      abi: artifact.abi,
      functionName: "owner",
    });

    expect(owner).toBe(delegator.address);
  });
});
