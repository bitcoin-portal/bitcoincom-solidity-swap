const Token = artifacts.require("Token");
const Weth = artifacts.require("WrappedEther");
const Maker = artifacts.require("LiquidityMaker");
// const Factory = artifacts.require("ISwapsFactory");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const { expectRevert } = require('@openzeppelin/test-helpers');
require("./utils");

const tokens = (value) => {
    return web3.utils.toWei(value.toString());
}

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
    // let verse;
    // let verseX;

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

        it("should be able to provide liquidity (WETH/DAI) using WETH", async () => {

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

            // should send LPs to depositor
            assert.equal(
                addedTo,
                depositor
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(tokenAmountA)
            );

            // should issue some LPs
            assert.isAtLeast(
                parseInt(tokenAmountLP),
                0
            );

            const contractDaiBalance = await dai.balanceOf(
                maker.address
            );

            const contractWethBalance = await weth.balanceOf(
                maker.address
            );

            // should not have any DAI leftover in contract
            assert.equal(
                parseInt(contractDaiBalance),
                0
            );

            // expect some WETH left in the contract as dust
            assert.isAtLeast(
                parseInt(contractWethBalance),
                1
            );

            // perform cleanup
            await maker.cleanUp(
                MAINNET_WRAPPED_ETH
            );

            const wethBalanceAfterCleanup = await weth.balanceOf(
                maker.address
            );

            // should not have any leftover
            assert.equal(
                parseInt(wethBalanceAfterCleanup),
                0
            );
        });

        it("should not allow to send ETH directly to the contract", async () => {
            const error = "function selector was not recognized and there's no fallback nor receive function";
            await expectRevert(
                maker.sendTransaction({
                    from: owner,
                    value: tokens(1)
                }),
                `Returned error: Error: Transaction reverted: ${error}`
            );
        });

        it("should be able to provide liquidity (WETH/DAI) using DAI", async () => {

            const depositor = alice;
            const daiAmount = 1800;
            const slipLastSwap = 10;
            const daiAmountDeposit = tokens(daiAmount);

            const ethAmount = (daiAmount - slipLastSwap) / ethPrice;
            const TOLERANCE = 0.99;

            const expectedAmountDai = tokens(daiAmount / 2);
            const expectedAmountEth = tokens(ethAmount / 2);

            const minLiquidityEth = tokens(ethAmount / 2 * TOLERANCE);
            const minLiquidityDai = tokens(daiAmount / 2 * TOLERANCE);

            await getSomeDai(
                depositor,
                daiAmountDeposit
            );

            await dai.approve(
                maker.address,
                daiAmountDeposit,
                {
                    from: depositor
                }
            );

            await maker.makeLiquidityDual(
                MAINNET_DAI_TOKEN,
                MAINNET_WRAPPED_ETH,
                daiAmountDeposit,
                expectedAmountEth,
                minLiquidityDai,
                minLiquidityEth,
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
                parseInt(expectedAmountDai)
            );

            assert.isAtLeast(
                parseInt(amountOut),
                parseInt(expectedAmountEth)
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(minLiquidityDai)
            );

            assert.isAtLeast(
                parseInt(amountOut),
                parseInt(minLiquidityEth)
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

            // should send LPs to depositor
            assert.equal(
                addedTo,
                depositor
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(tokenAmountA)
            );

            // should issue some LPs
            assert.isAtLeast(
                parseInt(tokenAmountLP),
                0
            );

            const contractDaiBalance = await dai.balanceOf(
                maker.address
            );

            // expect some leftover of DAI in contract
            assert.isAbove(
                parseInt(contractDaiBalance),
                0
            );

            // cleanup DAI dust
            await maker.cleanUp(
                MAINNET_DAI_TOKEN
            );

            const contractDaiBalanceAfter = await dai.balanceOf(
                maker.address
            );

            // should not have any leftover
            assert.equal(
                parseInt(contractDaiBalanceAfter),
                0
            );

            const contractWethBalance = await weth.balanceOf(
                maker.address
            );

            // should not have any WETH leftover in contract
            assert.equal(
                parseInt(contractWethBalance),
                0
            );
        });

        it("should be able to provide liquidity (WETH/DAI) using ETH", async () => {

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

            await maker.makeLiquidity(
                MAINNET_DAI_TOKEN,
                expectedAmountDai,
                minLiquidityEth,
                minLiquidityDai,
                {
                    from: depositor,
                    value: depositAmountEth
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

            // should send LPs to depositor
            assert.equal(
                addedTo,
                depositor
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(tokenAmountA)
            );

            // should issue some LPs
            assert.isAtLeast(
                parseInt(tokenAmountLP),
                0
            );

            const contractDaiBalance = await dai.balanceOf(
                maker.address
            );

            const contractWethBalance = await weth.balanceOf(
                maker.address
            );

            // should not have any DAI leftover in contract
            assert.equal(
                parseInt(contractDaiBalance),
                0
            );

            // expect some WETH left in the contract as dust
            assert.isAtLeast(
                parseInt(contractWethBalance),
                1
            );

            // perform cleanup
            await maker.cleanUp(
                MAINNET_WRAPPED_ETH
            );

            const wethBalanceAfterCleanup = await weth.balanceOf(
                maker.address
            );

            // should not have any leftover
            assert.equal(
                parseInt(wethBalanceAfterCleanup),
                0
            );
        });

        it("should be able to provide liquidity (WETH/DAI) using DAI", async () => {

            const depositor = alice;
            const daiAmount = 1800;
            const slipLastSwap = 10;
            const daiAmountDeposit = tokens(daiAmount);

            const ethAmount = (daiAmount - slipLastSwap) / ethPrice;
            const TOLERANCE = 0.99;

            const expectedAmountDai = tokens(daiAmount / 2);
            const expectedAmountEth = tokens(ethAmount / 2);

            const minLiquidityEth = tokens(ethAmount / 2 * TOLERANCE);
            const minLiquidityDai = tokens(daiAmount / 2 * TOLERANCE);

            await getSomeDai(
                depositor,
                daiAmountDeposit
            );

            await dai.approve(
                maker.address,
                daiAmountDeposit,
                {
                    from: depositor
                }
            );

            await maker.makeLiquidityDual(
                MAINNET_DAI_TOKEN,
                MAINNET_WRAPPED_ETH,
                daiAmountDeposit,
                expectedAmountEth,
                minLiquidityDai,
                minLiquidityEth,
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
                parseInt(expectedAmountDai)
            );

            assert.isAtLeast(
                parseInt(amountOut),
                parseInt(expectedAmountEth)
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(minLiquidityDai)
            );

            assert.isAtLeast(
                parseInt(amountOut),
                parseInt(minLiquidityEth)
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

            // should send LPs to depositor
            assert.equal(
                addedTo,
                depositor
            );

            assert.isAtLeast(
                parseInt(amountIn),
                parseInt(tokenAmountA)
            );

            // should issue some LPs
            assert.isAtLeast(
                parseInt(tokenAmountLP),
                0
            );

            const contractDaiBalance = await dai.balanceOf(
                maker.address
            );

            // expect some leftover of DAI in contract
            assert.isAbove(
                parseInt(contractDaiBalance),
                0
            );

            // cleanup DAI dust
            await maker.cleanUp(
                MAINNET_DAI_TOKEN
            );

            const contractDaiBalanceAfter = await dai.balanceOf(
                maker.address
            );

            // should not have any leftover
            assert.equal(
                parseInt(contractDaiBalanceAfter),
                0
            );

            const contractWethBalance = await weth.balanceOf(
                maker.address
            );

            // should not have any WETH leftover in contract
            assert.equal(
                parseInt(contractWethBalance),
                0
            );
        });
    });
});
