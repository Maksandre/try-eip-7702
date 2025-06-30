import { createPublicClient, createWalletClient, http } from "viem";
import { anvil } from "viem/chains";
import { expect } from "vitest";
import { privateKeyToAccount } from "viem/accounts";

import artifact from "../out/SmartWallet.sol/SmartWallet.json";

export const getConfig = async () => {
  const client = createPublicClient({
    chain: anvil,
    transport: http("http://127.0.0.1:8545"),
  });

  const walletClient = createWalletClient({
    chain: anvil,
    transport: http("http://127.0.0.1:8545"),
  });

  // Use the first anvil account
  const account = privateKeyToAccount(
    `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
  );

  // Deploy the contract
  const hash = await walletClient.deployContract({
    account,
    abi: artifact.abi,
    bytecode: artifact.bytecode.object as `0x${string}`,
    args: [],
  });

  // Wait for deployment
  const receipt = await client.waitForTransactionReceipt({ hash });

  // Verify contract is deployed
  expect(receipt.contractAddress).toBeDefined();
  expect(receipt.status).toBe("success");

  return {
    client,
    artifact,
    walletClient,
    account,
    implementationAddress: receipt.contractAddress as `0x${string}`,
  };
};
