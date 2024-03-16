// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.23;

interface IERC20 {

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool);
}
