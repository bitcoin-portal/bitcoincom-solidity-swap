// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

import "./IWETH.sol";
import "./IERC20.sol";
import "./ISwapsFactory.sol";
import "./ISwapsRouter.sol";

import "./SafeMath.sol";
import "./SwapsLibrary.sol";
import "./TransferHelper.sol";

contract SwapsRouter is ISwapsRouter {

    using SafeMath for uint;

    address public immutable FACTORY;
    address public immutable WETH;

    modifier ensure(
        uint256 _deadline
    ) {
        require(
            _deadline >= block.timestamp,
            'DEADLINE_EXPIRED'
        );
        _;
    }

    constructor(
        address _factory,
        address _WETH
    ) {
        FACTORY = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        require(
            msg.sender == WETH,
            'INVALID_ETH_SENDER'
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    )
        internal
        returns (uint256, uint256)
    {
        if (ISwapsFactory(FACTORY).getPair(_tokenA, _tokenB) == address(0x0)) {
            ISwapsFactory(FACTORY).createPair(_tokenA, _tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = SwapsLibrary.getReserves(
            FACTORY,
            _tokenA,
            _tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            return (
                _amountADesired,
                _amountBDesired
            );
        }

        uint256 amountBOptimal = SwapsLibrary.quote(
            _amountADesired,
            reserveA,
            reserveB
        );

        if (amountBOptimal <= _amountBDesired) {

            require(
                amountBOptimal >= _amountBMin,
                'INSUFFICIENT_B_AMOUNT'
            );

            return (
                _amountADesired,
                amountBOptimal
            );
        }

        uint256 amountAOptimal = SwapsLibrary.quote(
            _amountBDesired,
            reserveB,
            reserveA
        );

        assert(
            amountAOptimal <= _amountADesired
        );

        require(
            amountAOptimal >= _amountAMin,
            'INSUFFICIENT_A_AMOUNT'
        );

        return (
            amountAOptimal,
            _amountBDesired
        );
    }

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
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        address pair = pairFor(
            FACTORY,
            tokenA,
            tokenB
        );

        safeTransferFrom(
            tokenA,
            msg.sender,
            pair,
            amountA
        );

        safeTransferFrom(
            tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = ISwapsPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        address pair = pairFor(
            FACTORY,
            token,
            WETH
        );

        safeTransferFrom(
            token,
            msg.sender,
            pair,
            amountToken
        );

        IWETH(WETH).deposit{
            value: amountETH
        }();

        assert(
            IWETH(WETH).transfer(
                pair,
                amountETH
            )
        );

        liquidity = ISwapsPair(pair).mint(to);

        if (msg.value > amountETH) {
            unchecked {
                safeTransferETH(
                    msg.sender,
                    msg.value - amountETH
                );
            }
        }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        public
        ensure(deadline)
        returns (
            uint amountA,
            uint amountB
        )
    {
        address pair = pairFor(
            FACTORY,
            tokenA,
            tokenB
        );

        ISwapsPair(pair).transferFrom(
            msg.sender,
            pair,
            liquidity
        );

        (uint amount0, uint amount1) = ISwapsPair(pair).burn(to);
        (address token0,) = SwapsLibrary.sortTokens(tokenA, tokenB);

        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);

        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH
        )
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        safeTransfer(
            token,
            to,
            amountToken
        );

        IWETH(WETH).withdraw(
            amountETH
        );

        safeTransferETH(
            to,
            amountETH
        );
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (
            uint amountA,
            uint amountB
        )
    {
        address pair = pairFor(
            FACTORY,
            tokenA,
            tokenB
        );

        uint value = approveMax
            ? U256_MAX
            : liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        virtual
        override
        returns (
            uint amountToken,
            uint amountETH
        )
    {
        address pair = pairFor(
            FACTORY,
            token,
            WETH
        );

        uint value = approveMax
            ? U256_MAX
            : liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        ensure(deadline)
        returns (uint256 amountETH)
    {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );

        IWETH(WETH).withdraw(
            amountETH
        );

        safeTransferETH(
            to,
            amountETH
        );
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint amountETH)
    {
        address pair = pairFor(
            FACTORY,
            token,
            WETH
        );

        uint value = approveMax
            ? U256_MAX
            : liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function _swap(
        uint[] memory _amounts,
        address[] memory _path,
        address _to
    )
        internal
    {
        for (uint i; i < _path.length - 1; i++) {

            (address input, address output) = (_path[i], _path[i + 1]);
            (address token0,) = SwapsLibrary.sortTokens(
                input,
                output
            );

            uint amountOut = _amounts[i + 1];

            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));

            address to = i < _path.length - 2
                ? pairFor(FACTORY, output, _path[i + 2])
                : _to;

            ISwapsPair(
                pairFor(
                    FACTORY,
                    input,
                    output
                )
            ).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        amounts = SwapsLibrary.getAmountsOut(
            FACTORY,
            amountIn,
            path
        );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(
                FACTORY,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        amounts = SwapsLibrary.getAmountsIn(
            FACTORY,
            amountOut,
            path
        );

        require(
            amounts[0] <= amountInMax,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(
                FACTORY,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            to
        );
    }

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[0] == WETH,
            'INVALID_PATH'
        );

        amounts = SwapsLibrary.getAmountsOut(
            FACTORY,
            msg.value,
            _path
        );

        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        IWETH(WETH).deposit{
            value: amounts[0]
        }();

        assert(
            IWETH(WETH).transfer(
                pairFor(
                    FACTORY,
                    _path[0],
                    _path[1]
                ),
                amounts[0]
            )
        );

        _swap(
            amounts,
            _path,
            _to
        );
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(
            path[path.length - 1] == WETH,
            'INVALID_PATH'
        );

        amounts = SwapsLibrary.getAmountsIn(
            FACTORY,
            amountOut,
            path
        );

        require(
            amounts[0] <= amountInMax,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(
                FACTORY,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            address(this)
        );

        IWETH(WETH).withdraw(
            amounts[amounts.length - 1]
        );

        safeTransferETH(
            to,
            amounts[amounts.length - 1]
        );
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(
            path[path.length - 1] == WETH,
            'INVALID_PATH'
        );

        amounts = SwapsLibrary.getAmountsOut(
            FACTORY,
            amountIn,
            path
        );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(
                FACTORY,
                path[0],
                path[1]
            ),
            amounts[0]
        );

        _swap(
            amounts,
            path,
            address(this)
        );

        IWETH(WETH).withdraw(
            amounts[amounts.length - 1]
        );

        safeTransferETH(
            to,
            amounts[amounts.length - 1]
        );
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(
            path[0] == WETH,
            'INVALID_PATH'
        );

        amounts = SwapsLibrary.getAmountsIn(
            FACTORY,
            amountOut,
            path
        );

        require(
            amounts[0] <= msg.value,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        IWETH(WETH).deposit{
            value: amounts[0]
        }();

        assert(
            IWETH(WETH).transfer(
                pairFor(
                    FACTORY,
                    path[0],
                    path[1]
                ),
                amounts[0]
            )
        );

        _swap(
            amounts,
            path,
            to
        );
        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            unchecked {
                safeTransferETH(
                    msg.sender,
                    msg.value - amounts[0]
                );
            }
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapsLibrary.sortTokens(input, output);
            ISwapsPair pair = ISwapsPair(pairFor(FACTORY, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = SwapsLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? pairFor(FACTORY, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
    {
        safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(
                FACTORY,
                path[0],
                path[1]
            ),
            amountIn
        );

        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
    {
        require(
            path[0] == WETH,
            'INVALID_PATH'
        );

        uint256 amountIn = msg.value;

        IWETH(WETH).deposit{
            value: amountIn
        }();

        assert(
            IWETH(WETH).transfer(
                pairFor(
                    FACTORY,
                    path[0],
                    path[1]
                ),
                amountIn
            )
        );

        delete amountIn;
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swapSupportingFeeOnTransferTokens(
            path,
            to
        );

        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
    {
        require(
            path[path.length - 1] == WETH,
            'INVALID_PATH'
        );

        safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(
                FACTORY,
                path[0],
                path[1]
            ),
            amountIn
        );

        _swapSupportingFeeOnTransferTokens(
            path,
            address(this)
        );

        uint256 amountOut = IERC20(WETH).balanceOf(
            address(this)
        );

        require(
            amountOut >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        IWETH(WETH).withdraw(
            amountOut
        );

        safeTransferETH(
            to,
            amountOut
        );
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    )
        public
        pure
        returns (uint256 amountB)
    {
        return SwapsLibrary.quote(
            amountA,
            reserveA,
            reserveB
        );
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        public
        pure
        returns (uint256 amountOut)
    {
        return SwapsLibrary.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
    }

    function getAmountIn(
        uint256 _amountOut,
        uint256 _reserveIn,
        uint256 _reserveOut
    )
        public
        pure
        returns (uint256)
    {
        return SwapsLibrary.getAmountIn(
            _amountOut,
            _reserveIn,
            _reserveOut
        );
    }

    function getAmountsOut(
        uint256 _amountIn,
        address[] memory _path
    )
        public
        view
        returns (uint256[] memory)
    {
        return SwapsLibrary.getAmountsOut(
            FACTORY,
            _amountIn,
            _path
        );
    }

    function getAmountsIn(
        uint256 amountOut,
        address[]
        memory path
    )
        public
        view
        returns (uint256[] memory amounts)
    {
        return SwapsLibrary.getAmountsIn(
            FACTORY,
            amountOut,
            path
        );
    }

    function pairFor(
        address _factory,
        address _tokenA,
        address _tokenB
    )
        public
        pure
        returns (address)
    {
        return SwapsLibrary.pairFor(
            _factory,
            _tokenA,
            _tokenB
        );
    }
}
