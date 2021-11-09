// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

uint224 constant Q112 = 2 ** 112;
uint112 constant U112_MAX = 2 ** 112 - 1;

function encode(
    uint112 _y
)
    pure
    returns (uint224)
{
    unchecked {
        return uint224(_y) * Q112;
    }
}

function uqdiv(
    uint224 _x,
    uint112 _y
)
    pure
    returns (uint224)
{
    unchecked {
        return _x / uint224(_y);
    }
}

library Math {

    function min(
        uint256 _x,
        uint256 _y
    )
        internal
        pure
        returns (uint)
    {
        return _x < _y ? _x : _y;
    }

    function sqrt(
        uint256 _y
    )
        internal
        pure
        returns (uint256 z)
    {
        unchecked {
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
}
