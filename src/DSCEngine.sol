// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
// import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Validations} from "../utils/Validations.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Noah Harrison
 * @notice this is a study object
 */

contract DSCEngine is Validations, ReentrancyGuard {
    /* ERROR */
    error DSCEngine__TokenAddressesAndpriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransFerFaile();

    modifier isAllowedToken(address _token) {
        _isAllowedToken(_token);
        _;
    }

    /* state */
    mapping(address token => address priceFeeds) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) s_userAddressDeposit;
    mapping(address user => uint256 amountDscMinted) s_DSCMinted;
    // 抵押物的合约地址
    address[] private s_collarteralToken;

    DecentralizedStableCoin immutable i_dsc;

    event DepositCollateral(
        address indexed userAddress,
        address indexed tokenAddress,
        uint256 indexed amount
    );

    constructor(
        address[] memory tokenAddress,
        address[] memory priceFeedsAddress,
        address dscAddress
    ) {
        if (tokenAddress.length != priceFeedsAddress.length) {
            revert DSCEngine__TokenAddressesAndpriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i]] = priceFeedsAddress[i];
            s_collarteralToken.push(tokenAddress[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    function _isAllowedToken(address _token) internal view {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
    }

    /* 存入抵押并且铸造DSC */
    function depositCollateralAndMintDsc() external {}

    /* 只存入抵押品 不铸造 DSC ，因为铸造会影响 健康值  health factor */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 tokenAmount
    )
        external
        moreThanZero(tokenAmount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_userAddressDeposit[msg.sender][tokenCollateralAddress] += tokenAmount;
        emit DepositCollateral(msg.sender, tokenCollateralAddress, tokenAmount);
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        if (!success) revert DSCEngine__TransFerFaile();
    }

    /**
     *
     * @param amountDscToMint  铸造DSC数量
     * 1. 将铸造人存入 s_DSCMinted mapping 中
     * 2. 需要判断铸造人是否可以制造amountDscToMint的DSC，不能 mintAmount > collateral
     * 3. 需要判断健康值是否达标，不达标都应revert
     */
    function mintDsc(
        uint256 amountDscToMint
    ) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
    }

    /* 赎回抵押品并且销毁DSC */
    function redeemCollateralForDsc() external {}

    /* 赎回抵押品 */
    function redeemCollateral() external {}

    /* 销毁Dsc */
    function burnDsc() external {}

    /* 清算 */
    function liquidate() external {}

    /* 健康因子 */
    function getHealthFactor() external {}

    // private function
    /**
     * @param user 将要查询的用户地址
     * @return totalDscMinted  已经铸造DSC的数量
     * @return collateralValInUsd  抵押物品的 USDT 值
     */
    function _getAccountInformation(
        address user
    ) internal returns (uint256 totalDscMinted, uint256 collateralValInUsd) {}

    function _healthFactor(address user) internal returns (uint256) {
        (
            uint256 totalDscMinted,
            uint256 collateralValInUsd
        ) = _getAccountInformation(user);
    }

    function _revertIfHealthFactorIsBroken() internal {}

    //  view  pure
    /* 获取账号下抵押物品的数量 */
    function getAccountCollateralValue(
        address user
    ) public returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collarteralToken.length; i++) {
            address token = s_collarteralToken[i];
            uint256 amount = s_userAddressDeposit[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public returns (uint256) {
        // ('')
    }
}
