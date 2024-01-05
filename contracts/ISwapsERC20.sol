ISwapsERC20.sol// SPDX-License-Identifier: BCOM

pragma solidity =0.8.19;

interface ISwapsERC20 {

    function name()
        external
        pure
        returns (string memory);

    function symbol()
        external
        pure
        returns (string memory);

    function decimals()
        external
        pure
        returns (uint8);

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool);

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

    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32);

    function PERMIT_TYPEHASH()
        external
        pure
        returns (bytes32);

    function nonces(
        address _owner
    )
        external
        view
        returns (uint256);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
}
