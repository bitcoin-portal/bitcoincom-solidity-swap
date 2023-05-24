const Token = artifacts.require("Token");
const Weth = artifacts.require("WrappedEther");
const Maker = artifacts.require("LiquidityMaker");
const Factory = artifacts.require("ISwapsFactory");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
// const catchRevert = require("./exceptionsHelpers.js").catchRevert;
const { expectRevert } = require('@openzeppelin/test-helpers');
require("./utils");

// const BN = web3.utils.BN;

const tokens = (value) => {
    return web3.utils.toWei(value.toString());
}

const ONE_ETH = tokens(1);
const FOUR_ETH = tokens(4);
const FIVE_ETH = tokens(5);
const NINE_ETH = tokens(9);
const HALF_ETH = tokens(0.5);

const ethPrice = 1800;
const testBlock = 17274000;
// 1 ETH = ~$1800 @block 17274000 (on VerseDEX);
const getLastEvent = async (eventName, instance) => {
    const events = await instance.getPastEvents(eventName, {
        fromBlock: testBlock,
        toBlock: "latest",
    });
    return events.pop().returnValues;
};

const MAINNET_ROUTER = "0xB4B0ea46Fe0E9e8EAB4aFb765b527739F2718671";
const MAINNET_FACTORY = "0xee3E9E46E34a27dC755a63e2849C9913Ee1A06E2";
const MAINNET_WRAPPED_ETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const MAINNET_VERSE_TOKEN = "0x249cA82617eC3DfB2589c4c17ab7EC9765350a18";
const MAINNET_DAI_TOKEN = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const MAINNET_DEV_ADDRESS = "0x641AD78BAca220C5BD28b51Ce8e0F495e85Fe689";

const getSomeDai = async (
    beneficiary,
    amount
) => {
    await helpers.impersonateAccount(
        MAINNET_DEV_ADDRESS
    );

    const impersonatedSigner = await ethers.getSigner(
        MAINNET_DEV_ADDRESS
    );

    let daiEthers = await ethers.getContractAt(
        "Token",
        MAINNET_DAI_TOKEN
    );

    await daiEthers.connect(impersonatedSigner).transfer(
        beneficiary,
        amount
    );
}

contract("LiquidityMaker", ([owner, alice, bob, random]) => {

    let dai;
    let weth;
    let maker;
    let verse;
    let verseX;

    beforeEach(async () => {
        maker = await Maker.new(
            MAINNET_ROUTER,
            MAINNET_FACTORY
        );

        weth = await Weth.at(
            MAINNET_WRAPPED_ETH
        );

        dai = await Token.at(
            MAINNET_DAI_TOKEN
        );

        verse = await Token.at(
            MAINNET_VERSE_TOKEN
        );
    });

    describe("Initial deployment functionality", () => {

        it("should be able to deploy and check initial values", async () => {

            const router = await maker.ROUTER();
            const factory = await maker.FACTORY();

            assert.equal(
                router,
                MAINNET_ROUTER
            );

            assert.equal(
                factory,
                MAINNET_FACTORY
            );
        });
    });

    describe("Initial liquidity functionality", () => {

        it("should be able to provide liquidity (WETH/DAI) using WEHT", async () => {

            const depositor = alice;

            const ethAmount = 1;
            const daiAmount = ethAmount * ethPrice;
            const TOLERANCE = 0.99;

            const depositAmountEth = tokens(ethAmount);
            const expectedAmountDai = tokens(daiAmount / 2);
            const expectedAmountEth = tokens(ethAmount / 2);

            const minLiquidityEth = tokens(ethAmount / 2 * TOLERANCE);
            const minLiquidityDai = tokens(daiAmount / 2 * TOLERANCE);

            const balanceBefore = await weth.balanceOf(
                depositor
            );

            await weth.send(
                depositAmountEth,
                {
                    from: depositor
                }
            );

            const balanceAfter = await weth.balanceOf(
                depositor
            );

            const balanceChange = balanceAfter.sub(
                balanceBefore
            );

            assert.equal(
                balanceChange.toString(),
                depositAmountEth.toString()
            );

            await weth.approve(
                maker.address,
                depositAmountEth,
                {
                    from: depositor
                }
            );

            await maker.makeLiquidityDual(
                MAINNET_WRAPPED_ETH,
                MAINNET_DAI_TOKEN,
                depositAmountEth,
                expectedAmountDai,
                minLiquidityEth,
                minLiquidityDai,
                {
                    from: depositor
                }
            );

            const { amountIn, amountOut } = await getLastEvent(
                "SwapResults",
                maker
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(expectedAmountEth)
            );

            assert.isAtLeast(
                parseInt(amountOut),
                parseInt(expectedAmountDai)
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(minLiquidityEth)
            );

            assert.isAtLeast(
                parseInt(amountOut),
                parseInt(minLiquidityDai)
            );

            const {
                tokenAmountA,
                tokenAmountB,
                tokenAmountLP,
                addedTo
            } = await getLastEvent(
                "LiquidityAdded",
                maker
            );

            assert.equal(
                amountOut,
                tokenAmountB
            );

            assert.equal(
                addedTo,
                depositor
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(tokenAmountA)
            );

            assert.isAtLeast(
                parseInt(tokenAmountLP),
                0
            );
        });

        it("should be able to provide liquidity (WETH/DAI) using DAI", async () => {

            const depositor = alice;
            const depositAmountDai = tokens(1820);
            const minEthExpected = HALF_ETH;

            await getSomeDai(
                depositor,
                depositAmountDai
            );

            await dai.approve(
                maker.address,
                depositAmountDai,
                {
                    from: depositor
                }
            );

            await maker.makeLiquidityDual(
                MAINNET_DAI_TOKEN,
                MAINNET_WRAPPED_ETH,
                depositAmountDai,
                minEthExpected,
                0,
                0,
                {
                    from: depositor
                }
            );
        });
    });
});
