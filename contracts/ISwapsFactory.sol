// SPDX-License-Identifier: BCOM

pragma solidity =0.8.14;

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
        address _tokenA,
        address _tokenB
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
        address _tokenA,
        address _tokenB
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

    function cloneTarget()
        external
        view
        returns (address target);
}
