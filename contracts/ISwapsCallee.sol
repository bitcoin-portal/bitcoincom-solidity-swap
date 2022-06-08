// SPDX-License-Identifier: BCOM

pragma solidity =0.8.14;

interface ISwapsCallee {

    function swapsCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    )
        external;
}
