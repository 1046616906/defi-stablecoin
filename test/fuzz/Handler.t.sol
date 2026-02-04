// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";

contract Handler is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    address weth;
    address wbtc;

    uint96 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DecentralizedStableCoin _dsc, DSCEngine _dscEngine) {
        dsc = _dsc;
        dscEngine = _dscEngine;
        address[] memory collarteralToken = dscEngine.getCollarteralToken();
        weth = collarteralToken[0];
        wbtc = collarteralToken[1];
    }

    function depositCollateral(
        uint256 collateralSeed,
        uint256 collateralAmount
    ) public {
        address collateralToken = _getCollateralSeed(collateralSeed);
        collateralAmount = bound(collateralAmount, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        ERC20Mock(collateralToken).mint(msg.sender, collateralAmount);
        ERC20Mock(collateralToken).approve(
            address(dscEngine),
            collateralAmount
        );
        dscEngine.depositCollateral(collateralToken, collateralAmount);
        vm.stopPrank();
    }

    function _getCollateralSeed(
        uint256 collaterSeed
    ) internal view returns (address) {
        if (collaterSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
