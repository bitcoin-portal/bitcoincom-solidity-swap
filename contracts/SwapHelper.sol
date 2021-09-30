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
        return uint224(_y) * Q112; // never overflows
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
        return _x / uint224(_y); // pre-checked above zero
    }
}
