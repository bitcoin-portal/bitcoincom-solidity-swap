// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.23;

import "./IERC20.sol";
import "./ISwapsPair.sol";
import "./ISwapsRouter.sol";

contract LiquidityManager {

    address public owner;
    address public worker;

    ISwapsPair public pair;
    ISwapsRouter public router;

    address public token0;
    address public token1;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Caller is not the owner"
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == worker,
            "Caller is not the worker"
        );
        _;
    }

    constructor() {

        owner = msg.sender;
        worker = msg.sender;

        router = ISwapsRouter(
            0xB4B0ea46Fe0E9e8EAB4aFb765b527739F2718671
        );

        token0 = 0x249cA82617eC3DfB2589c4c17ab7EC9765350a18;
        token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        pair = ISwapsPair(
            router.pairFor(
                router.FACTORY(),
                token0,
                token1
            )
        );
    }

    function buyBackVerseToken(
        uint256 _liquidityAmountToUse,
        uint256 _expectMinVerseRemoved,
        uint256 _expectMinWethRemoved,
        uint256 _minAmountVerseToBuy,
        uint256 _maxAmountWethForSwap,
        uint256 _desiredVerseToAddBack,
        uint256 _desiredWethToAddBack,
        uint256 _expectMinVerseToAddBack,
        uint256 _expectMinWethToAddBack
    )
        external
        onlyWorker
    {
        pair.approve(
            address(router),
            _liquidityAmountToUse
        );

        router.removeLiquidity(
            token0,
            token1,
            _liquidityAmountToUse,
            _expectMinVerseRemoved,
            _expectMinWethRemoved,
            address(this),
            block.timestamp
        );

        (
            uint256 reserve0,
            uint256 reserve1,
        ) = router.getReserves(
            router.FACTORY(),
            token0,
            token1
        );

        uint256 requiredWethForSwap = router.quote(
            _minAmountVerseToBuy,
            reserve0,
            reserve1
        );

        if (requiredWethForSwap > _maxAmountWethForSwap) {
            revert("LiquidityManager: TOO_EXPENSIVE");
        }

        router.swapExactTokensForTokens(
            requiredWethForSwap,
            _minAmountVerseToBuy,
            _getSwapPathFromWethToVerse(),
            address(this),
            block.timestamp
        );

        IERC20(token0).approve(
            address(router),
            _desiredVerseToAddBack
        );

        IERC20(token1).approve(
            address(router),
            _desiredWethToAddBack
        );

        router.addLiquidity(
            token0,
            token1,
            _desiredVerseToAddBack,
            _desiredWethToAddBack,
            _expectMinVerseToAddBack,
            _expectMinWethToAddBack,
            address(this),
            block.timestamp
        );
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    )
        external
        onlyOwner
    {
        IERC20(_token).transfer(
            _to,
            _amount
        );
    }

    function withdrawETH(
        address _to,
        uint256 _amount
    )
        external
        onlyOwner
    {
        payable(_to).transfer(
            _amount
        );
    }

    function setWorker(
        address _worker
    )
        external
        onlyOwner
    {
        worker = _worker;
    }

    function _getSwapPathFromWethToVerse()
        private
        view
        returns (address[] memory path)
    {
        path = new address[](2);
        path[0] = token1; // WETH
        path[1] = token0; // VERSE
    }
}
