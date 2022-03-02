// SPDX-License-Identifier: BCOM

pragma solidity =0.8.12;

contract SwapsHelper {

    uint256 constant UINT256_MAX = type(uint256).max;
    address constant ZERO_ADDRESS = address(0);

    function sortTokens(
        address _tokenA,
        address _tokenB
    )
        internal
        pure
        returns (
            address token0,
            address token1
        )
    {
        require(
            _tokenA != _tokenB,
            "SwapsHelper: IDENTICAL_ADDRESSES"
        );

        (token0, token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        require(
            token0 != ZERO_ADDRESS,
            "SwapsHelper: ZERO_ADDRESS"
        );
    }

    function quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    )
        public
        pure
        returns (uint256 amountB)
    {
        require(
            _amountA > 0,
            "SwapsHelper: INSUFFICIENT_AMOUNT"
        );

        require(
            _reserveA > 0 && _reserveB > 0,
            "SwapsHelper: INSUFFICIENT_LIQUIDITY"
        );

        amountB = _amountA
            * _reserveB
            / _reserveA;
    }

    function getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    )
        public
        pure
        returns (uint256 amountOut)
    {
        require(
            _amountIn > 0,
            "SwapsHelper: INSUFFICIENT_INPUT_AMOUNT"
        );

        require(
            _reserveIn > 0 && _reserveOut > 0,
            "SwapsHelper: INSUFFICIENT_LIQUIDITY"
        );

        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = _reserveIn * 1000 + amountInWithFee;

        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint256 _amountOut,
        uint256 _reserveIn,
        uint256 _reserveOut
    )
        public
        pure
        returns (uint256 amountIn)
    {
        require(
            _amountOut > 0,
            "SwapsHelper: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        require(
            _reserveIn > 0 &&
            _reserveOut > 0,
            "SwapsHelper: INSUFFICIENT_LIQUIDITY"
        );

        uint256 numerator = _reserveIn * _amountOut * 1000;
        uint256 denominator = (_reserveOut - _amountOut) * 997;

        amountIn = numerator / denominator + 1;
    }


    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)"
            )
        )
    );

    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                "transferFrom(address,address,uint256)"
            )
        )
    );

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "SwapsHelper: TRANSFER_FAILED"
        );
    }

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "SwapsHelper: TRANSFER_FROM_FAILED"
        );
    }

    function _safeTransferETH(
        address to,
        uint256 value
    )
        internal
    {
        (bool success,) = to.call{
            value: value
        }(new bytes(0));

        require(
            success,
            "SwapsHelper: ETH_TRANSFER_FAILED"
        );
    }

    function _pairFor(
        address _factory,
        address _tokenA,
        address _tokenB,
        address _implementation
    )
        internal
        pure
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
}
