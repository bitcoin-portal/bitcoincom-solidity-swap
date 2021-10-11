// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

interface ISwapsCallee {

    function swapsCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )
        external;
}
