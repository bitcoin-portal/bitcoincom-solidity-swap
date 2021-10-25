# bitcoincom-solidity-swap

This repository contains smart-contracts for the swap between token A and token B or
token A to ETH / ETH to token A.


### Process and Testing

The package can be run as a CLI for testing purposes.

🔗 First start a local chain:

```
npm run chain
```

Then run test commands for contract deployment and testing


🚀 This command runs token tests:
```
npm run test-token
```


🌯 This command runs wrapped ether tests:
```
npm run test-wraps
```


🏭 This command runs swap router / swap factory tests:
```
npm run test-swaps
```

### Test coverage

🧪 To generate test-coverage report simply run this command (without starting local chain)

```
npm run test-coverage
```

🧪 expected-latest results:
```
---------------------|----------|----------|----------|----------|----------------|
File                 |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
---------------------|----------|----------|----------|----------|----------------|
 contracts/          |    80.61 |    53.08 |    83.52 |    80.54 |                |
  IERC20.sol         |      100 |      100 |      100 |      100 |                |
  ISwapsCallee.sol   |      100 |      100 |      100 |      100 |                |
  ISwapsERC20.sol    |      100 |      100 |      100 |      100 |                |
  ISwapsFactory.sol  |      100 |      100 |      100 |      100 |                |
  ISwapsPair.sol     |      100 |      100 |      100 |      100 |                |
  ISwapsRouter.sol   |      100 |      100 |      100 |      100 |                |
  IWETH.sol          |      100 |      100 |      100 |      100 |                |
  SwapsFactory.sol   |    97.81 |       70 |      100 |    99.27 |            226 |
  SwapsHelper.sol    |      100 |      100 |      100 |      100 |                |
  SwapsLibrary.sol   |      100 |       55 |      100 |      100 |                |
  SwapsRouter.sol    |       50 |    34.62 |    46.43 |    49.29 |... 9,1074,1090 |
  Token.sol          |      100 |      100 |      100 |      100 |                |
  TransferHelper.sol |      100 |       50 |      100 |      100 |                |
  WrappedEther.sol   |      100 |      100 |      100 |      100 |                |
---------------------|----------|----------|----------|----------|----------------|
All files            |    80.61 |    53.08 |    83.52 |    80.54 |                |
---------------------|----------|----------|----------|----------|----------------|
```
