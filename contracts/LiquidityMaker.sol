// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.19;

import "./IWETH.sol";
import "./ISwapsPair.sol";
import "./ISwapsRouter.sol";
import "./ISwapsFactory.sol";
import "./LiquidityHelper.sol";

contract LiquidityMaker is LiquidityHelper {

    address immutable WETH_ADDRESS;
    address immutable ROUTER_ADDRESS;

    IWETH public immutable WETH;
    ISwapsRouter public immutable ROUTER;
    ISwapsFactory public immutable FACTORY;

    event SwapResults(
        uint256 amountIn,
        uint256 amountOut
    );

    event LiquidityAdded(
        uint256 amountAdded,
        address indexed addedTo
    );

    constructor(
        ISwapsRouter _router,
        ISwapsFactory _factory
    ) {
        ROUTER_ADDRESS = address(
            _router
        );

        ROUTER = _router;
        FACTORY = _factory;

        WETH_ADDRESS = ROUTER.WETH();

        WETH = IWETH(
            WETH_ADDRESS
        );
    }

    /**
     * @dev
     * Optimal one-sided supply
     * 1. Swaps optimal amount from token A to token B
     * 2. Adds liquidity for token A and token B pair
    */
    function makeLiquidity(
        address _tokenAddress,
        uint256 _expectedTokenAmount,
        uint256 _minimumLiquidityEther,
        uint256 _minimumLiquidityToken
    )
        external
        payable
        returns (uint256)
    {
        _wrapEther(
            msg.value
        );

        return _makeLiquidity(
            WETH_ADDRESS,
            _tokenAddress,
            msg.value,
            _expectedTokenAmount,
            _minimumLiquidityEther,
            _minimumLiquidityToken,
            msg.sender
        );
    }

    /**
     * @dev
     * Optimal one-sided supply
     * 1. Swaps optimal amount from token A to token B
     * 2. Adds liquidity for token A and token B pair
    */
    function makeLiquidityDual(
        address _tokenA,
        address _tokenB,
        uint256 _initialAmountA,
        uint256 _expectedAmountB,
        uint256 _minimumLiquidityA,
        uint256 _minimumLiquidityB
    )
        external
        payable
        returns (uint256)
    {
        _safeTransferFrom(
            _tokenA,
            msg.sender,
            address(this),
            _initialAmountA
        );

        return _makeLiquidity(
            _tokenA,
            _tokenB,
            _initialAmountA,
            _expectedAmountB,
            _minimumLiquidityA,
            _minimumLiquidityB,
            msg.sender
        );
    }

    function _makeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _initialAmountA,
        uint256 _expectedAmountB,
        uint256 _minimumLiquidityA,
        uint256 _minimumLiquidityB,
        address _beneficiaryAddress
    )
        internal
        returns (uint256)
    {
        ISwapsPair pair = _getPair(
            _tokenA,
            _tokenB
        );

        (
            uint256 reserve0,
            uint256 reserve1,
        ) = pair.getReserves();

        uint256 swapAmount = pair.token0() == _tokenA
            ? getSwapAmount(reserve0, _initialAmountA)
            : getSwapAmount(reserve1, _initialAmountA);

        uint256[] memory swapResults = _swap(
            _tokenA,
            _tokenB,
            swapAmount,
            _expectedAmountB
        );

        emit SwapResults(
            swapResults[0],
            swapResults[1]
        );

        uint256 lpTokenAmount = _addLiquidity(
            _tokenA,
            _tokenB,
            swapResults[0],
            swapResults[1],
            _minimumLiquidityA,
            _minimumLiquidityB,
            _beneficiaryAddress
        );

        emit LiquidityAdded(
            lpTokenAmount,
            _beneficiaryAddress
        );

        return swapAmount;
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _swapAmountIn,
        uint256 _expectedAmountOut
    )
        internal
        returns (uint256[] memory)
    {
        ISwapsERC20(_tokenIn).approve(
            ROUTER_ADDRESS,
            MAX_VALUE
        );

        return ROUTER.swapExactTokensForTokens(
            _swapAmountIn,
            _expectedAmountOut,
            _makePath(
                _tokenIn,
                _tokenOut
            ),
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _minTokenA,
        uint256 _minTokenB,
        address _beneficiary
    )
        internal
        returns (uint256)
    {
        ISwapsERC20(_tokenB).approve(
            ROUTER_ADDRESS,
            _amountB
        );

        (
            ,
            ,
            uint256 liquidity
        ) = ROUTER.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            _minTokenA,
            _minTokenB,
            _beneficiary,
            block.timestamp
        );

        return liquidity;
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
     *
    */
    function _wrapEther(
        uint256 _amount
    )
        private
    {
        WETH.deposit{value: _amount}();
    }
}
