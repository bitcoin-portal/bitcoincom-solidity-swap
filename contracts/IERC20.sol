// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

interface IERC20 {

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);
}
