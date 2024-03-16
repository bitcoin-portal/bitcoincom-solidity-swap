// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.23;

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
        returns (uint256);

    function mint(
        address _to
    )
        external
        returns (uint256 liquidity);

    function burn(
        address _to
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1
        );

    function swap(
        uint256 _amount0Out,
        uint256 _amount1Out,
        address _to,
        bytes calldata _data
    )
        external;

    function skim()
        external;

    function initialize(
        address,
        address
    )
        external;
}
