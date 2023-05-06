// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./ISwapsPair.sol";
import "./ISwapsRouter.sol";
import "./ISwapsFactory.sol";

contract LiquidityManager {

    ISwapsFactory immutable FACTORY;
    ISwapsRouter immutable ROUTER;

    address immutable ROUTER_ADDRESS;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        ISwapsFactory _factory,
        ISwapsRouter _router
    ) {
        FACTORY = _factory;
        ROUTER = _router;

        ROUTER_ADDRESS = address(
            _router
        );
    }

    /**
     * @dev
     * Optimal one-sided supply
     * 1. Swaps optimal amount from token A to token B
     * 2. Adds liquidity for token A and token B pair
    */
    function makeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _minExpected
    )
        external
        returns (uint256 swapAmount)
    {
        IERC20(_tokenA).transferFrom(
            msg.sender,
            address(this),
            _amountA
        );

        ISwapsPair pair = _getPair(
            _tokenA,
            _tokenB
        );

        (
            uint256 reserve0,
            uint256 reserve1,
        ) = pair.getReserves();

        swapAmount = pair.token0() == _tokenA
            ? getSwapAmount(reserve0, _amountA)
            : getSwapAmount(reserve1, _amountA);

        _swap(
            _tokenA,
            _tokenB,
            swapAmount,
            _minExpected
        );

        _addLiquidity(
            _tokenA,
            _tokenB
        );
    }

    function _swap(
        address _fromToken,
        address _toToken,
        uint256 _swapAmount,
        uint256 _minExpected
    )
        internal
    {
        IERC20(_fromToken).approve(
            ROUTER_ADDRESS,
            _swapAmount
        );

        address[] memory path = new address[](2);
        path = new address[](2);

        path[0] = _fromToken;
        path[1] = _toToken;

        ROUTER.swapExactTokensForTokens(
            _swapAmount,
            _minExpected,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB
    )
        internal
    {
        uint256 balanceA = IERC20(_tokenA).balanceOf(
            address(this)
        );

        uint256 balanceB = IERC20(_tokenB).balanceOf(
            address(this)
        );

        IERC20(_tokenA).approve(
            ROUTER_ADDRESS,
            balanceA
        );

        IERC20(_tokenB).approve(
            ROUTER_ADDRESS,
            balanceB
        );

        ROUTER.addLiquidity(
            _tokenA,
            _tokenB,
            balanceA,
            balanceB,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _getPair(
        address _tokenA,
        address _tokenB
    )
        internal
        view
        returns (ISwapsPair)
    {
        return ISwapsPair(
            FACTORY.getPair(
                _tokenA,
                _tokenB
            )
        );
    }

    /**
     * @dev
     * s = optimal swap amount
     * r = amount of reserve for token a
     * a = amount of token a the user currently has (not added to reserve yet)
     * f = swap fee percent
     * s = (sqrt(((2 - f)r)^2 + 4(1 - f)ar) - (2 - f)r) / (2(1 - f))
    */
    function getSwapAmount(
        uint256 _r,
        uint256 _a
    )
        public
        pure
        returns (uint256)
    {
        return (sqrt(_r * (_r * 3988009 + _a * 3988000)) - _r * 1997) / 1994;
    }

    /**
     * @dev
     *
    */
    function sqrt(
        uint256 _y
    )
        private
        pure
        returns (uint256 z)
    {
        if (_y > 3) {
            z = _y;
            uint256 x = _y / 2 + 1;
            while (x < z) {
                z = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z = 1;
        }
    }
}
