# EIP-7702 Code Examples

A collection of code examples demonstrating EIP-7702 (Externally Owned Account to Smart Contract Wallet) functionality.

## What is EIP-7702?

EIP-7702 enables EOAs to temporarily become smart contract wallets by setting their code, allowing for advanced wallet features while maintaining EOA simplicity.

## Setup

```sh
# Install dependencies
forge soldeer install
yarn install
```

## Structure

- **Contracts**: `src/` - Smart wallet implementations and examples
- **Tests**: `test/` - Foundry and TypeScript test suites
- **Examples**: Social recovery, batch operations, collision prevention

## Usage

```sh
# Run Foundry tests
forge test

# Run TypeScript tests
yarn test

# Start local node (Prague hardfork)
yarn anvil
```

## Available Scripts

- `yarn test` - Run TypeScript tests with Vitest
- `yarn test:run` - Run tests once
- `yarn test:ui` - Run tests with UI
- `yarn test:forge` - Run Foundry tests
- `yarn anvil` - Start local node with Prague hardfork