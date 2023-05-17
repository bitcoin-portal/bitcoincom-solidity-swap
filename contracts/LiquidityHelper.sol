// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.19;

import "./IERC20.sol";

contract LiquidityHelper {

    uint256 constant MAX_VALUE = type(uint256).max;

    function _makePath(
        address _tokenIn,
        address _tokenOut
    )
        internal
        pure
        returns (address[] memory path)
    {
        path = new address[](2);

        path[0] = _tokenIn;
        path[1] = _tokenOut;

        return path;
    }

    /**
     * @dev Allows to execute transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(_token);

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }

    function _callOptionalReturn(
        address _token,
        bytes memory _data
    )
        private
    {
        (
            bool success,
            bytes memory returndata
        ) = _token.call(_data);

        require(
            success,
            "LiquidityHelper: CALL_FAILED"
        );

        if (returndata.length > 0) {
            require(
                abi.decode(
                    returndata,
                    (bool)
                ),
                "LiquidityHelper: OPERATION_FAILED"
            );
        }
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
        return (
            _sqrt(
                _r * (_r * 3988009 + _a * 3988000)
            ) - _r * 1997
        ) / 1994;
    }

    /**
     * @dev
     *
    */
    function _sqrt(
        uint256 _y
    )
        internal
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
