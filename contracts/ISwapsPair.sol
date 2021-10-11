// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

import "./ISwapsERC20.sol";

interface ISwapsPair is ISwapsERC20 {

    function MINIMUM_LIQUIDITY()
        external
        pure
        returns (uint256);

    function factory()
        external
        view
        returns (address);

    function token0()
        external
        view
        returns (address);

    function token1()
        external
        view
        returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast()
        external
        view
        returns (uint256);

    function price1CumulativeLast()
        external
        view
        returns (uint256);

    function kLast()
        external
        view
        returns (uint);

    function mint(
        address to
    )
        external
        returns (uint liquidity);

    function burn(
        address to
    )
        external
        returns (
            uint amount0,
            uint amount1
        );

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    )
        external;

    function skim(
        address to
    )
        external;

    function sync()
        external;

    function initialize(
        address,
        address
    )
        external;
}
