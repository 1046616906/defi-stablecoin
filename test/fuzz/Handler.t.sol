// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";

contract Handler is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    address weth;
    address wbtc;
    uint256 public ghostVariable = 0;
    address[] userAddress;
    MockV3Aggregator wethUsdPriceFeed;
    uint96 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DecentralizedStableCoin _dsc, DSCEngine _dscEngine) {
        dsc = _dsc;
        dscEngine = _dscEngine;
        address[] memory collarteralToken = dscEngine.getCollarteralToken();
        weth = collarteralToken[0];
        wbtc = collarteralToken[1];

        wethUsdPriceFeed = MockV3Aggregator(
            dscEngine.getCollateralPriceFeed(weth)
        );
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
        userAddress.push(msg.sender);
    }

    // function redeemCollateral(
    //     uint256 collateralSeed,
    //     uint256 redeemAmount
    // ) public {
    //     address collateralAddress = _getCollateralSeed(collateralSeed);
    //     uint256 maxCollateralToRedeem;
    //     (uint256 totalDscMinted, uint256 collateralValInUsd) = dscEngine
    //         .getAccountInformation(msg.sender);

    //     if (totalDscMinted == 0) {
    //         maxCollateralToRedeem = dscEngine.getUserCollateralAmount(
    //             msg.sender,
    //             collateralAddress
    //         );
    //     } else {
    //         int256 maxCollateralToRedeemInUsd = int256(collateralValInUsd) /
    //             2 -
    //             int256(totalDscMinted);
    //         if (maxCollateralToRedeemInUsd < 0) return;
    //         // 通过剩余价值 来算出 可以赎回 抵押物 的 数量
    //         maxCollateralToRedeem = dscEngine.getTokenAmountFormUsd(
    //             collateralAddress,
    //             uint256(maxCollateralToRedeemInUsd) * 2
    //         );
    //         // user
    //     }

    //     redeemAmount = bound(redeemAmount, 0, maxCollateralToRedeem);
    //     console.log("redeemAmount:", redeemAmount);
    //     if (redeemAmount == 0) return;
    //     vm.prank(msg.sender);
    //     dscEngine.redeemCollateral(collateralAddress, redeemAmount);
    // }

    function redeemCollateral(
        uint256 collateralSeed,
        uint256 collateralAmount
    ) public {
        // 1. 选定 token 和 sender (记得统一使用你的用户池)
        address collateralToken = _getCollateralSeed(collateralSeed);
        if (userAddress.length == 0) return;
        address sender = userAddress[collateralSeed % userAddress.length];

        // 2. 获取账户当前状态
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine
            .getAccountInformation(sender);

        // 3. 计算最大可赎回的 USD 价值
        // 如果没借钱，全部都能取
        uint256 maxCollateralToRedeemInUsd;
        if (totalDscMinted == 0) {
            maxCollateralToRedeemInUsd = collateralValueInUsd;
        } else {
            // 必须保留的抵押品价值 = (负债 * 100) / 50 (即 2 倍负债)
            uint256 minCollateralRequired = (totalDscMinted * 100) / 50;

            if (collateralValueInUsd <= minCollateralRequired) {
                return; // 已经处于清算边缘，不能再取了
            }
            maxCollateralToRedeemInUsd =
                collateralValueInUsd -
                minCollateralRequired;
        }

        // 4. 将 USD 价值转换回 Token 数量
        uint256 maxTokenToRedeem = dscEngine.getTokenAmountFormUsd(
            collateralToken,
            maxCollateralToRedeemInUsd
        );

        // 5. 还要和账面余额取最小值（防止精度误差）
        uint256 userBalance = dscEngine.getUserCollateralAmount(
            sender,
            collateralToken
        );
        maxTokenToRedeem = uint256(bound(maxTokenToRedeem, 0, userBalance));

        // 6. 执行赎回
        collateralAmount = bound(collateralAmount, 0, maxTokenToRedeem);
        if (collateralAmount == 0) return;

        vm.prank(sender);
        dscEngine.redeemCollateral(collateralToken, collateralAmount);
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (userAddress.length == 0) return;
        address sender = userAddress[addressSeed % userAddress.length];
        (uint256 totalDscMinted, uint256 collateralValInUsd) = dscEngine
            .getAccountInformation(sender);

        int256 maxMintDscAmount = int256(collateralValInUsd) /
            2 -
            int256(totalDscMinted);
        if (maxMintDscAmount < 0) return;

        amount = bound(amount, 0, uint256(maxMintDscAmount));
        if (amount == 0) return;
        vm.prank(sender);
        dscEngine.mintDsc(amount);
        ghostVariable++;
    }

    function updateWethUsdPriceFeed(uint96 newPrice) public {
        int256 newPriceInt = int256(uint256(newPrice));
        wethUsdPriceFeed.updateAnswer(newPriceInt);
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
