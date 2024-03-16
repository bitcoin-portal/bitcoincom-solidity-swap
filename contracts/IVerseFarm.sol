// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.23;

import "./ISwapsPair.sol";

interface IVerseFarm {

    function earned(
        address _farmerAdders
    )
        external
        view
        returns (uint256);

    function balanceOf(
        address _farmerAdders
    )
        external
        view
        returns (uint256);

    function stakeToken()
        external
        view
        returns (ISwapsPair);
}
