// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

import "./IUniswapV2Pair.sol";

library SwapsLibrary {

    function sortTokens(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (
            address token0,
            address token1
        )
    {
        require(
            tokenA != tokenB,
            'IDENTICAL_ADDRESSES'
        );

        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        require(
            token0 != address(0x0),
            'ZERO_ADDRESS'
        );
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sortTokens(
            tokenA,
            tokenB
        );

        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(
                                abi.encodePacked(
                                    token0,
                                    token1
                                )
                            ),
                            // hex'4e769ee398923525ee6655071d658be32e15b33e7786e3b22f916b37ac05be80'
                            hex'460da99920eb880188503b89ba4d72586b8206165f1ab493fb53789c9a405da0'
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint reserveA,
            uint reserveB
        )
    {
        (address token0,) = sortTokens(
            tokenA,
            tokenB
        );

        (uint reserve0, uint reserve1,) = IUniswapV2Pair(
            pairFor(
                factory,
                tokenA,
                tokenB
            )
        ).getReserves();

        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves,
    // returns an equivalent amount of the other asset
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    )
        internal
        pure
        returns (uint amountB)
    {
        require(
            amountA > 0,
            'INSUFFICIENT_AMOUNT'
        );

        require(
            reserveA > 0 && reserveB > 0,
            'INSUFFICIENT_LIQUIDITY'
        );

        amountB = amountA
            * reserveB
            / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        require(
            amountIn > 0,
            'INSUFFICIENT_INPUT_AMOUNT'
        );

        require(
            reserveIn > 0 && reserveOut > 0,
            'INSUFFICIENT_LIQUIDITY'
        );

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;

        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves,
    // returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountIn)
    {
        require(
            amountOut > 0,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        require(
            reserveIn > 0 && reserveOut > 0,
            'INSUFFICIENT_LIQUIDITY'
        );

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut
    // calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    )
        internal
        view
        returns (uint[] memory amounts)
    {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn
    // calculations on any number of pairs

    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path
    )
        internal
        view
        returns (uint[] memory amounts)
    {
        require(
            path.length >= 2,
            'INVALID_PATH'
        );

        amounts = new uint[](path.length);

        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
