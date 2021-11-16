// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

interface IWETH {

    function deposit()
        external
        payable;

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    function withdraw(
        uint256
    )
        external;
}
