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
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event LiquidityAdded(
        uint256 tokenAmountA,
        uint256 tokenAmountB,
        uint256 tokenAmountLP,
        address indexed tokenA,
        address indexed tokenB,
        address indexed addedTo
    );

    event CleanUp(
        uint256 tokenAmount,
        ISwapsERC20 indexed tokenAddress
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
     * Optimal one-sided supply using ETH
     * 1. Swaps optimal amount from ETH to ERC20
     * 2. Adds liquidity for ETH and Token pair
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
     * Optimal one-sided supply using ERC20
     * 1. Swaps optimal amount from ERC20-A to ERC20-B
     * 2. Adds liquidity for _tokenA and _tokenB pair
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
    {
        _safeTransferFrom(
            _tokenA,
            msg.sender,
            address(this),
            _initialAmountA
        );

        _makeLiquidity(
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

        uint256[] memory swapResults = _swapTokens(
            _tokenA,
            _tokenB,
            swapAmount,
            _expectedAmountB
        );

        emit SwapResults(
            _tokenA,
            _tokenB,
            swapResults[0],
            swapResults[1]
        );

        _addLiquidity(
            _tokenA,
            _tokenB,
            swapResults[0],
            swapResults[1],
            _minimumLiquidityA,
            _minimumLiquidityB,
            _beneficiaryAddress
        );

        return swapAmount;
    }

    /**
     * @dev
     * Uses swapExactTokensForTokens to split provided value
     * 1. Swaps optimal amount from _tokenIn to _tokenOut
     * return swap amounts as a result (input and ouput)
    */
    function _swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _swapAmountIn,
        uint256 _expectedAmountOut
    )
        private
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

    /**
     * @dev
     * Adds liquidity for _tokenA and _tokenB pair
     * can send LP tokens to _beneficiary address
    */
    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _minTokenA,
        uint256 _minTokenB,
        address _beneficiary
    )
        private
    {
        ISwapsERC20(_tokenB).approve(
            ROUTER_ADDRESS,
            _amountB
        );

        (
            uint256 tokenAmountA,
            uint256 tokenAmountB,
            uint256 tokenAmountLP
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

        emit LiquidityAdded(
            tokenAmountA,
            tokenAmountB,
            tokenAmountLP,
            _tokenA,
            _tokenB,
            _beneficiary
        );
    }

    /**
     * @dev
     * Read address of the pair
     * by calling FACTORY contract
    */
    function _getPair(
        address _tokenA,
        address _tokenB
    )
        private
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
     * Allows to wrap Ether
     * by calling WETH contract
    */
    function _wrapEther(
        uint256 _amount
    )
        private
    {
        WETH.deposit{value: _amount}();
    }

    /**
     * @dev
     * Allows to cleanup any tokens stuck
     * in the contract as leftover dust or
     * if accidentally sent to the contract
    */
    function cleanUp(
        ISwapsERC20 _token
    )
        external
    {
        uint256 balance = _token.balanceOf(
            address(this)
        );

        _token.transfer(
            FACTORY.feeTo(),
            balance
        );

        emit CleanUp(
            balance,
            _token
        );
    }
}
