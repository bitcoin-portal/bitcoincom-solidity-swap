// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

import "./IWETH.sol";
import "./IERC20.sol";
import "./ISwapsFactory.sol";
import "./ISwapsPair.sol";
import "./TransferHelper.sol";

contract SwapsRouter {

    address public immutable FACTORY;
    address public immutable WETH;
    address public immutable PAIR;

    modifier ensure(
        uint256 _deadline
    ) {
        require(
            _deadline >= block.timestamp,
            'SwapsRouter: DEADLINE_EXPIRED'
        );
        _;
    }

    constructor(
        address _factory,
        address _WETH
    ) {
        FACTORY = _factory;
        WETH = _WETH;
        PAIR = ISwapsFactory(_factory).cloneTarget();
    }

    receive()
        external
        payable
    {
        require(
            msg.sender == WETH,
            'SwapsRouter: INVALID_SENDER'
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

        (uint256 reserveA, uint256 reserveB) = getReserves(
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

        uint256 amountBOptimal = quote(
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

        uint256 amountAOptimal = quote(
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
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin
        );

        address pair = _pairFor(
            FACTORY,
            _tokenA,
            _tokenB,
            PAIR
        );

        _safeTransferFrom(
            _tokenA,
            msg.sender,
            pair,
            amountA
        );

        _safeTransferFrom(
            _tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = ISwapsPair(pair).mint(_to);
    }

    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        external
        payable
        ensure(_deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            _token,
            WETH,
            _amountTokenDesired,
            msg.value,
            _amountTokenMin,
            _amountETHMin
        );

        address pair = _pairFor(
            FACTORY,
            _token,
            WETH,
            PAIR
        );

        _safeTransferFrom(
            _token,
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

        liquidity = ISwapsPair(pair).mint(_to);

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
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        public
        ensure(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB
        )
    {
        address pair = _pairFor(
            FACTORY,
            _tokenA,
            _tokenB,
            PAIR
        );

        ISwapsPair(pair).transferFrom(
            msg.sender,
            pair,
            _liquidity
        );

        (uint amount0, uint amount1) = ISwapsPair(pair).burn(_to);

        (address token0,) = sortTokens(
            _tokenA,
            _tokenB
        );

        (amountA, amountB) = _tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);

        require(
            amountA >= _amountAMin,
            'INSUFFICIENT_A_AMOUNT'
        );

        require(
            amountB >= _amountBMin,
            'INSUFFICIENT_B_AMOUNT'
        );
    }

    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        public
        ensure(_deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH
        )
    {
        (amountToken, amountETH) = removeLiquidity(
            _token,
            WETH,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        _safeTransfer(
            _token,
            _to,
            amountToken
        );

        IWETH(WETH).withdraw(
            amountETH
        );

        safeTransferETH(
            _to,
            amountETH
        );
    }

    function removeLiquidityWithPermit(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        returns (uint256, uint256)
    {
        address pair = _pairFor(
            FACTORY,
            _tokenA,
            _tokenB,
            PAIR
        );

        uint value = _approveMax
            ? U256_MAX
            : _liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            _deadline,
            _v,
            _r,
            _s
        );

        return removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _amountAMin,
            _amountBMin,
            _to,
            _deadline
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
        returns (uint256, uint256)
    {
        address pair = _pairFor(
            FACTORY,
            token,
            WETH,
            PAIR
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

        return removeLiquidityETH(
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

        _safeTransfer(
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
        returns (uint256 amountETH)
    {
        address pair = _pairFor(
            FACTORY,
            token,
            WETH,
            PAIR
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

            (address input, address output) = (
                _path[i],
                _path[i + 1]
            );

            (address token0,) = sortTokens(
                input,
                output
            );

            uint amountOut = _amounts[i + 1];

            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));

            address to = i < _path.length - 2
                ? _pairFor(FACTORY, output, _path[i + 2], PAIR)
                : _to;

            ISwapsPair(
                _pairFor(
                    FACTORY,
                    input,
                    output,
                    PAIR
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
        amounts = getAmountsOut(
            FACTORY,
            amountIn,
            path
        );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        _safeTransferFrom(
            path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                path[0],
                path[1],
                PAIR
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
        amounts = getAmountsIn(
            FACTORY,
            amountOut,
            path
        );

        require(
            amounts[0] <= amountInMax,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        _safeTransferFrom(
            path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                path[0],
                path[1],
                PAIR
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

        amounts = getAmountsOut(
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
                _pairFor(
                    FACTORY,
                    _path[0],
                    _path[1],
                    PAIR
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

        amounts = getAmountsIn(
            FACTORY,
            amountOut,
            path
        );

        require(
            amounts[0] <= amountInMax,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        _safeTransferFrom(
            path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                path[0],
                path[1],
                PAIR
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
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            path[path.length - 1] == WETH,
            'INVALID_PATH'
        );

        amounts = getAmountsOut(
            FACTORY,
            amountIn,
            path
        );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        _safeTransferFrom(
            path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                path[0],
                path[1],
                PAIR
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

        amounts = getAmountsIn(
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
                _pairFor(
                    FACTORY,
                    path[0],
                    path[1],
                    PAIR
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

    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    )
        internal
    {
        for (uint i; i < path.length - 1; i++) {

            (address input, address output) = (
                path[i],
                path[i + 1]
            );

            (address token0,) = sortTokens(
                input,
                output
            );

            ISwapsPair pair = ISwapsPair(
                _pairFor(
                    FACTORY,
                    input,
                    output,
                    PAIR
                )
            );

            uint amountInput;
            uint amountOutput;

            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();

            (uint reserveInput, uint reserveOutput) = input == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? _pairFor(FACTORY, output, path[i + 2], PAIR) : _to;

            pair.swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
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
        _safeTransferFrom(
            path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                path[0],
                path[1],
                PAIR
            ),
            amountIn
        );

        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swapSupportingFeeOnTransferTokens(
            path,
            to
        );

        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
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
                _pairFor(
                    FACTORY,
                    path[0],
                    path[1],
                    PAIR
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
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
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
            'SwapsRouter: INVALID_PATH'
        );

        _safeTransferFrom(
            path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                path[0],
                path[1],
                PAIR
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
        address _factory,
        address _tokenA,
        address _tokenB
    )
        external
        view
        returns (address predicted)
    {
        predicted = _pairFor(
            _factory,
            _tokenA,
            _tokenB,
            PAIR
        );
    }


    function _pairFor(
        address _factory,
        address _tokenA,
        address _tokenB,
        address _implementation
    )
        internal
        view
        returns (address predicted)
    {
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        bytes32 salt = keccak256(
            abi.encodePacked(
                token0,
                token1
            )
        );

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, _factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
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

        (uint reserve0, uint reserve1,) = ISwapsPair(
            _pairFor(
                factory,
                tokenA,
                tokenB,
                PAIR
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

    // given an input amount of an asset and pair reserves,
    // returns the maximum output amount of the other asset

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
        require(
            path.length >= 2,
            'INVALID_PATH'
        );

        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {

            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );

            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut
            );
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

        amounts = new uint[](
            path.length
        );

        amounts[amounts.length - 1] = amountOut;

        for (uint i = path.length - 1; i > 0; i--) {

            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );

            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }
}
