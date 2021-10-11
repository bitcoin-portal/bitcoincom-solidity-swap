// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

interface ISwapsFactory {

    function feeTo()
        external
        view
        returns (address);

    function feeToSetter()
        external
        view
        returns (address);

    function getPair(
        address tokenA,
        address tokenB
    )
        external
        view
        returns (address pair);

    function allPairs(uint256)
        external
        view
        returns (address pair);

    function allPairsLength()
        external
        view
        returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    )
        external
        returns (address pair);

    function setFeeTo(
        address
    )
        external;

    function setFeeToSetter(
        address
    )
        external;
}
