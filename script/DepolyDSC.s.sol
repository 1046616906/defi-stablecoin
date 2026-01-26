// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract DeppluDSC is Script {
    function run() external returns (DSCEngine, DecentralizedStableCoin) {
        vm.startBroadcast();
        DecentralizedStableCoin decentralizedStableCoin = new DecentralizedStableCoin();
        // DSCEngine dscEngine = new DSCEngine();
        vm.stopBroadcast();
        // return (dscEngine, decentralizedStableCoin);
    }
}
