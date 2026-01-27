// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {Validations} from "../../utils/Validations.sol";

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

    function test_GetUsdVal() external view {
        uint256 amount = 10e18;
        uint256 allAssets = 10000e18;
        uint256 usdVal = dscEngine.getUsdValue(weth, amount);
        // 10 * 1000 = 10000e18
        assertEq(usdVal, allAssets);
    }

    function test_Revert_CollateralAmountZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.expectRevert(Validations.Validations__MustBeMoreThanZero.selector);
        vm.stopPrank();
        dscEngine.depositCollateral(wethUsdPriceFeed, 0);
    }
}
