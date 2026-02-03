// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract Invariant is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig config;

    function setUp() public {
        DeployDSC deployDSC = new DeployDSC();
        (dscEngine, dsc, config) = deployDSC.run();
    }
}
