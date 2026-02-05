// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        DeployDSC deployDSC = new DeployDSC();

        (dscEngine, dsc, config) = deployDSC.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
        // targetContract(address(dscEngine));
        handler = new Handler(dsc, dscEngine);
        targetContract(address(handler));
        // console.log(handler.ghostVariable());
    }

    function invariant_protocalMustHaveMoreValueThanTotalSuppy() external view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 totalUsdValue =
            dscEngine.getUsdValue(weth, totalWethDeposited) + dscEngine.getUsdValue(wbtc, totalWbtcDeposited);

        assert(totalUsdValue >= totalSupply);
        console.log(handler.ghostVariable());
    }
}
