// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console, stdError} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {Validations} from "../../utils/Validations.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DSCEngineTest is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;
    uint256 constant COLLATERAL_AMOUNT = 10 ether;
    uint256 constant INIT_AMOUNT = 10 ether;

    address public USER = makeAddr("user");

    function setUp() public {
        DeployDSC deployDsc = new DeployDSC();
        (dscEngine, dsc, helperConfig) = deployDsc.run();
        (
            wethUsdPriceFeed,
            wbtcUsdPriceFeed,
            weth,
            wbtc,
            deployerKey
        ) = helperConfig.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, INIT_AMOUNT);
    }

    // test price
    function test_GetUsdVal() external view {
        uint256 amount = 10e18;
        uint256 allAssets = 10000e18;
        uint256 usdVal = dscEngine.getUsdValue(weth, amount);
        // 10 * 1000 = 10000e18
        assertEq(usdVal, allAssets);
    }

    function test_GetTokenAmountFormUsd() external view {
        uint256 usdAmount = 1000 ether;
        uint256 expectWeth = 1 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFormUsd(weth, usdAmount);
        assertEq(expectWeth, actualWeth);
    }

    // constructor test
    function test_Revert_TokenAddressLengthNotEqualPriceFeedsAddress()
        external
    {
        tokenAddress.push(weth);
        priceFeedsAddress.push(wethUsdPriceFeed);
        priceFeedsAddress.push(wbtcUsdPriceFeed);
        vm.expectRevert(
            DSCEngine
                .DSCEngine__TokenAddressesAndpriceFeedAddressesMustBeSameLength
                .selector
        );
        new DSCEngine(tokenAddress, priceFeedsAddress, address(dsc));
    }

    // test DepositCollateral
    address[] tokenAddress;
    address[] priceFeedsAddress;

    modifier collateralDeposited() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), INIT_AMOUNT);
        dscEngine.depositCollateral(weth, INIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function test_Revert_CollateralAmountZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.expectRevert(Validations.Validations__MustBeMoreThanZero.selector);
        vm.stopPrank();
        dscEngine.depositCollateral(wethUsdPriceFeed, 0);
    }

    function test_Revert_WithUnapprovedCollateral() external {
        ERC20Mock testToken = new ERC20Mock("TK", "TK", USER, 10 ether);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(testToken), 10 ether);
        vm.stopPrank();
    }

    function test_GetAccountInformation() external collateralDeposited {
        (uint256 totalDscMinted, uint256 collateralValInUsd) = dscEngine
            .getAccountInformation(USER);
        assertEq(totalDscMinted, 0);
        assertEq(collateralValInUsd, 10000 ether);
    }

    function test_CanDepositCollateralWithoutMinting()
        external
        collateralDeposited
    {
        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, 0);
    }

    // mintDSC test
    // function test_Revert_IfHealthFactorIsBroken() external collateralDeposited {
    //     (, int256 price, , , ) = MockV3Aggregator(ethUsdPriceFeed)
    //         .latestRoundData();
    //     amountToMint =
    //         (amountCollateral *
    //             (uint256(price) * dsce.getAdditionalFeedPrecision())) /
    //         dsce.getPrecision();
    //     vm.prank(USER);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             DSCEngine.DSCEngine__BreaksHealthFactor.selector,
    //             expectedHealthFactor
    //         )
    //     );
    //     dscEngine.mintDsc(20000 ether);
    //     // (uint256 totalDscMinted, ) = dscEngine.getAccountInformation(USER);
    //     // assertEq(totalDscMinted, 20000 ether);
    // }

    // redeemCollateral  test
    function test_redeemCollateral_fail() external {
        vm.prank(USER);
        vm.expectRevert(stdError.arithmeticError);
        dscEngine.redeemCollateral(weth, INIT_AMOUNT);
    }

    function test_CollateralRedeemed() external collateralDeposited {
        vm.prank(USER);
        dscEngine.redeemCollateral(weth, INIT_AMOUNT);
        uint256 totalCollateralAmount = dscEngine.getUserCollateralAmount(
            USER,
            weth
        );
        assertEq(totalCollateralAmount, 0);
    }

    function test_Revert_BreaksHealthFactor() external {}
}
