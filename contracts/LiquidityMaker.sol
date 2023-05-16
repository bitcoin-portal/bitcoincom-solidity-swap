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
        uint256 amountOUt
    );

    event LiquidityAdded(
        uint256 amountAdded
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
        address _tokenB,
        uint256 _expectedAmountB,
        uint256 _minEther,
        uint256 _minToken
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
            _tokenB,
            msg.value,
            _expectedAmountB,
            _minEther,
            _minToken,
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
        uint256 _depositAmountA,
        uint256 _expectedAmountB,
        uint256 _minTokenA,
        uint256 _minTokenB
    )
        external
        payable
        returns (uint256)
    {
        _safeTransferFrom(
            _tokenA,
            msg.sender,
            address(this),
            _depositAmountA
        );

        return _makeLiquidity(
            _tokenA,
            _tokenB,
            _depositAmountA,
            _expectedAmountB,
            _minTokenA,
            _minTokenB,
            msg.sender
        );
    }

    /**
     * @dev
     * Optimal one-sided supply
     * 1. Swaps optimal amount from token A to token B
     * 2. Adds liquidity for token A and token B pair
    */
    function _makeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _depositAmountA,
        uint256 _expectedAmountB,
        uint256 _minTokenA,
        uint256 _minTokenB,
        address _beneficiary
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
            ? getSwapAmount(reserve0, _depositAmountA)
            : getSwapAmount(reserve1, _depositAmountA);

        // uint256[] memory swapResult =

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
            _minTokenA, // swapResult[0],
            _minTokenB, // swapResult[1],
            _beneficiary
        );

        emit LiquidityAdded(
            lpTokenAmount
        );

        return swapAmount;
    }

    function stakeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _depositAmountA,
        uint256 _expectedAmountB
        // uint256 _minTokenA,
        // uint256 _minTokenB
        // address _verseFarm
    )
        external
        returns (uint256 swapAmount)
    {
        ISwapsERC20(_tokenA).transferFrom(
            msg.sender,
            address(this),
            _depositAmountA
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
            ? getSwapAmount(reserve0, _depositAmountA)
            : getSwapAmount(reserve1, _depositAmountA);

        uint256[] memory swapResult = _swap(
            _tokenA,
            _tokenB,
            swapAmount,
            _expectedAmountB
        );

        uint256 liquidity = _addLiquidity(
            _tokenA,
            _tokenB,
            swapResult[0],
            swapResult[1],
            address(this)
        );

        emit LiquidityAdded(
            liquidity
        );

        // _farmDeposit(
        // );
    }

    function _swap(
        address _fromToken,
        address _toToken,
        uint256 _swapAmount,
        uint256 _expectedAmountOut
    )
        internal
        returns (uint256[] memory)
    {
        ISwapsERC20(_fromToken).approve(
            ROUTER_ADDRESS,
            _swapAmount
        );

        address[] memory path = new address[](2);
        path = new address[](2);

        path[0] = _fromToken;
        path[1] = _toToken;

        return ROUTER.swapExactTokensForTokens(
            _swapAmount,
            _expectedAmountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _minTokenA,
        uint256 _minTokenB,
        address _recipient
    )
        internal
        returns (uint256)
    {
        uint256 balanceA = ISwapsERC20(_tokenA).balanceOf(
            address(this)
        );

        uint256 balanceB = ISwapsERC20(_tokenB).balanceOf(
            address(this)
        );

        ISwapsERC20(_tokenA).approve(
            ROUTER_ADDRESS,
            balanceA
        );

        ISwapsERC20(_tokenB).approve(
            ROUTER_ADDRESS,
            balanceB
        );

        (
            ,
            ,
            uint256 liquidity
        ) = ROUTER.addLiquidity(
            _tokenA,
            _tokenB,
            balanceA,
            balanceB,
            _minTokenA,
            _minTokenB,
            _recipient,
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
