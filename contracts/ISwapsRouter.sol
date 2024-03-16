// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.23;

interface ISwapsRouter {

    function WETH()
        external
        returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint[] memory amounts
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB
        );

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        external
        view
        returns (
            uint112 reserveA,
            uint112 reserveB,
            uint32 blockTimestampLast
        );

    function FACTORY()
        external
        view
        returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    )
        external
        pure
        returns (uint256 amountB);

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    )
        external
        pure
        returns (address);
}
