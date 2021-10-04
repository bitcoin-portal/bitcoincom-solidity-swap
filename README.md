# bitcoincom-solidity-swap

This repository contains smart-contracts for the swap between token A and token B or
token A to ETH / ETH to token A.


### Process and Testing

The package can be run as a CLI for testing purposes.

First start a local chain

```
npm run chain
```

Then run test commands for contract deployment and testing

--
This command runs token tests:
```
npm run test-token
```

--
This command runs wrapped ether tests:
```
npm run test-wraps
```

--
This command runs swap router / swap factory tests:
```
npm run test-swaps
```

### Test coverage

To generate test-coverage report simply run this command (without starting local chain)

```
npm run test-coverage
```
