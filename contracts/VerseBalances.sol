// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.23;

import "./IVerseFarm.sol";
import "./ISwapsERC20.sol";

contract VerseBalances {

    ISwapsPair[] public lpPairs;
    IVerseFarm[] public verseFarms;

    ISwapsERC20 public immutable VERSE_TOKEN;
    IVerseFarm public immutable VERSE_STAKING;

    uint256 public immutable LP_COUNT;
    uint256 public immutable FARM_COUNT;

    constructor(
        IVerseFarm _verseStaking,
        ISwapsPair[] memory _lpTokens,
        IVerseFarm[] memory _verseFarms
    ) {
        lpPairs = _lpTokens;
        verseFarms = _verseFarms;

        LP_COUNT = _lpTokens.length;
        FARM_COUNT = _verseFarms.length;

        VERSE_TOKEN = _verseStaking.stakeToken();
        VERSE_STAKING = _verseStaking;
    }

    function getTotalVerse(
        address _verseHolderAddress
    )
        external
        view
        returns (uint256 totalVerse)
    {
        (totalVerse, , , , , , ) = getTotalVerseBreakDown(
            _verseHolderAddress
        );
    }

    function getTotalVerseBreakDown(
        address _verseHolderAddress
    )
        public
        view
        returns (
            uint256 totalVerse,
            uint256 verseLiquid,
            uint256 verseStaked,
            uint256 verseInFarms,
            uint256 verseInPools,
            uint256 verseEarnedStaked,
            uint256 verseEarnedFarmed
        )
    {
        verseLiquid = calculateLiquidVerse(
            _verseHolderAddress
        );

        (
            verseStaked,
            verseEarnedStaked
        ) = calculateVerseInStaking(
            _verseHolderAddress
        );

        (
            verseInFarms,
            verseEarnedFarmed
        ) = calculateVerseInFarms(
            _verseHolderAddress
        );

        verseInPools = calculateVerseInPools(
            _verseHolderAddress
        );

        totalVerse = verseLiquid
            + verseStaked
            + verseInFarms
            + verseInPools
            + verseEarnedStaked
            + verseEarnedFarmed;
    }

    function calculateLiquidVerse(
        address _verseHolderAddress
    )
        public
        view
        returns (uint256 verseAmount)
    {
        return VERSE_TOKEN.balanceOf(
            _verseHolderAddress
        );
    }

    function calculateVerseInStaking(
        address _lpTokenHolderAddress
    )
        public
        view
        returns (
            uint256 verseStaked,
            uint256 verseEarned
        )
    {
        verseEarned = VERSE_STAKING.earned(
            _lpTokenHolderAddress
        );

        verseStaked = VERSE_STAKING.balanceOf(
            _lpTokenHolderAddress
        );
    }

    function calculateVerseInFarms(
        address _lpTokenHolderAddress
    )
        public
        view
        returns (
            uint256 verseInFarms,
            uint256 verseEarned
        )
    {
        uint256 i;
        uint256 l = FARM_COUNT;

        while (i < l) {
            (
                uint256 inFarmAmount,
                uint256 earnedAmount
            ) = calculateVerseInFarm(
                verseFarms[i],
                _lpTokenHolderAddress
            );

            verseInFarms += inFarmAmount;
            verseEarned += earnedAmount;

            unchecked {
                ++i;
            }
        }
    }

    function calculateVerseInFarm(
        IVerseFarm _verseFarm,
        address _lpTokenHolderAddress
    )
        public
        view
        returns (
            uint256 verseInFarm,
            uint256 verseEarned
        )
    {
        verseEarned = _verseFarm.earned(
            _lpTokenHolderAddress
        );

        uint256 verseLP = _verseFarm.balanceOf(
            _lpTokenHolderAddress
        );

        verseInFarm = _calculateVerseInLP(
            _verseFarm.stakeToken(),
            verseLP
        );
    }

    function calculateVerseInPools(
        address _lpTokenHolderAddress
    )
        public
        view
        returns (uint256 verseAmount)
    {
        uint256 i;
        uint256 l = LP_COUNT;

        while (i < l) {
            verseAmount += calculateVerseInLP(
                lpPairs[i],
                _lpTokenHolderAddress
            );

            unchecked {
                ++i;
            }
        }
    }

    function calculateBulkVerseInLP(
        ISwapsPair[] calldata _lpTokenAddress,
        address _lpTokenHolderAddress
    )
        public
        view
        returns (uint256 verseAmount)
    {
        uint256 i;
        uint256 l = _lpTokenAddress.length;

        while (i < l) {
            verseAmount += calculateVerseInLP(
                _lpTokenAddress[i],
                _lpTokenHolderAddress
            );

            unchecked {
                ++i;
            }
        }
    }

    function calculateVerseInLP(
        ISwapsPair _lpTokenAddress,
        address _lpTokenHolderAddress
    )
        public
        view
        returns (uint256 verseAmount)
    {
        uint256 lpAmount = _lpTokenAddress.balanceOf(
            _lpTokenHolderAddress
        );

        verseAmount = _calculateVerseInLP(
            _lpTokenAddress,
            lpAmount
        );
    }

    function _calculateVerseInLP(
        ISwapsPair _lpTokenAddress,
        uint256 _lpTokenAmount
    )
        internal
        view
        returns (uint256 verseAmount)
    {
        address token0 = _lpTokenAddress.token0();
        address token1 = _lpTokenAddress.token1();

        uint256 balance0 = ISwapsERC20(token0).balanceOf(
            address(_lpTokenAddress)
        );

        uint256 balance1 = ISwapsERC20(token1).balanceOf(
            address(_lpTokenAddress)
        );

        uint256 totalSupply = _lpTokenAddress.totalSupply();

        uint256 token0Amount = (balance0 * _lpTokenAmount) / totalSupply;
        uint256 token1Amount = (balance1 * _lpTokenAmount) / totalSupply;

        if (token0 == address(VERSE_TOKEN)) {
            return token0Amount;
        }

        if (token1 == address(VERSE_TOKEN)) {
            return token1Amount;
        }

        return 0;
    }
}
