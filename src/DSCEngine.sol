// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DSCEngine
 * @author Noah Harrison
 * @notice this is a study object
 */

contract DSCEngine {
    /* 存入抵押并且铸造DSC */
    function depositCollateralAndMintDsc() external {}

    /* 只存入抵押品 不铸造 DSC ，因为铸造会影响 健康值  health factor */
    function depositCollateral() external {}

    /* 铸造Dsc */
    function mintDes() external () {}

    /* 赎回抵押品并且销毁DSC */
    function redeemCollateralForDsc() external {}

    /* 赎回抵押品 */
    function redeemCollateral() external {}

    /* 销毁Dsc */
    function burnDsc() external {}

    /* 清算 */
    function liquidate() external () {}

    /* 健康因子 */
    function getHealthFactor() external {}
}
