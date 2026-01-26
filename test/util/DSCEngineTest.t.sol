// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    function setUp() public {
        DeployDSC deployDsc = new DeployDSC();
        (dscEngine, dsc, helperConfig) = deployDsc.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeNetworkConfig();
    }

    function test_GetUsdVal() external {
        uint256 amount = 10e18;
        uint256 allAssets = 10000e18;
        uint256 usdVal = dscEngine.getUsdValue(weth, amount);
        console.log(usdVal);
        // 10 * 1000 = 10000e18
        assertEq(usdVal, allAssets);
    }
}
