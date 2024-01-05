IERC20.sol// SPDX-License-Identifier: BCOM

pragma solidity =0.8.19;

interface IERC20 {

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);
}
