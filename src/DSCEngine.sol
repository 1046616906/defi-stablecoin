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
    error DSCEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error DSCEngine__MintFailed();
    modifier isAllowedToken(address _token) {
        _isAllowedToken(_token);
        _;
    }

    //  state =============================================
    uint256 private constant PRECISION = 1e18; // 精确度
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //清算阈值
    uint256 private constant LIQUIDATION_PRECISION = 100; // 计算精度
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; // 最低阈值

    mapping(address token => address priceFeeds) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) s_userAddressDeposit;
    mapping(address user => uint256 amountDscMinted) s_DSCMinted;
    // 抵押物的合约地址
    address[] private s_collarteralToken;

    DecentralizedStableCoin immutable i_dsc;

    //  function =============================================

    event DepositCollateral(address indexed userAddress, address indexed tokenAddress, uint256 indexed amount);
    event CollateralRedeemed(address indexed userAddress, address indexed tokenAddress, uint256 indexed amount);

    constructor(address[] memory tokenAddress, address[] memory priceFeedsAddress, address dscAddress) {
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
    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 tokenAmount, uint256 amountDscToMint)
        external
    {
        depositCollateral(tokenCollateralAddress, tokenAmount);
        mintDsc(amountDscToMint);
    }

    /* 只存入抵押品 不铸造 DSC ，因为铸造会影响 健康值  health factor */
    function depositCollateral(address tokenCollateralAddress, uint256 tokenAmount)
        public
        moreThanZero(tokenAmount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_userAddressDeposit[msg.sender][tokenCollateralAddress] += tokenAmount;
        emit DepositCollateral(msg.sender, tokenCollateralAddress, tokenAmount);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), tokenAmount);
        if (!success) revert DSCEngine__TransFerFaile();
    }

    /**
     *
     * @param amountDscToMint  铸造DSC数量
     * 1. 将铸造人存入 s_DSCMinted mapping 中
     * 2. 需要判断铸造人是否可以制造amountDscToMint的DSC，不能 mintAmount > collateral
     * 3. 需要判断健康值是否达标，不达标都应revert
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) revert DSCEngine__MintFailed();
    }

    /* 赎回抵押品并且销毁DSC */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 tokenAmount, uint256 burnMount) external {
        burnDsc(burnMount);
        redeemCollateral(tokenCollateralAddress, tokenAmount);
    }

    /* 赎回抵押品 */
    function redeemCollateral(address tokenCollateralAddress, uint256 tokenAmount)
        public
        moreThanZero(tokenAmount)
        nonReentrant
    {
        s_userAddressDeposit[msg.sender][tokenCollateralAddress] -= tokenAmount;
        emit CollateralRedeemed(msg.sender, tokenCollateralAddress, tokenAmount);
        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, tokenAmount);
        if (!success) revert DSCEngine__TransFerFaile();
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /* 销毁Dsc */
    function burnDsc(uint256 amountDsc) public moreThanZero(amountDsc) nonReentrant {
        s_DSCMinted[msg.sender] -= amountDsc;
        bool success = i_dsc.transferFrom(msg.sender, address(this), amountDsc);
        if (success) revert DSCEngine__TransFerFaile();
        i_dsc.burn(amountDsc);
        _revertIfHealthFactorIsBroken(msg.sender); // 理论上 销毁dsc _revertIfHealthFactorIsBroken永远不会触发
    }

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
    function _getAccountInformation(address user)
        internal
        view
        returns (uint256 totalDscMinted, uint256 collateralValInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValInUsd = getAccountCollateralValue(user);
    }

    /**
     *
     * @param user 用户地址
     * 想判断出用户的健康值，需要用户 已经铸造的DSC的总数（totalDscMinted） 和  抵押货币的总价值
     * 公式  collateralValInUsd * 清算阈值  / totalDscMinted   1000 * 0.5 / 100  = 5； 5>1
     */
    function _healthFactor(address user) internal view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValInUsd) = _getAccountInformation(user);
        /**
         * collateralAdjustedForThreshold 可借出的数量 也可以称之为 打折的价格
         * 2000 * 50 / 100  ===== 2000 / 2 = 1000
         * collateralAdjustedForThreshold = 1000   totalDscMinted = 100
         * 1000 * 1e18 / 100  =  10 * 1e19
         */
        uint256 collateralAdjustedForThreshold = (collateralValInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    /**
     *
     * @param user  用户地址
     * 1. 获取用户的健康值
     * 2. 判断健康值 是否大于 最低的阈值
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //  view  pure =======================================================
    /* 获取账号下抵押物品的数量 */
    /**
     *
     * @param user 用户的地址
     * 1. constructor 中 创建一个包含所有 token 的 Array
     * 2. 遍历数组，获取用户存入该token的数量
     * 3. 通过token 和 数量 获取用户的抵押品的总金额
     */
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collarteralToken.length; i++) {
            address token = s_collarteralToken[i];
            uint256 amount = s_userAddressDeposit[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    /**
     *
     * @param token 代币地址
     * @param amount 代币数量
     * 使用AggregatorV3Interface获取每个货币的价格来计算传入的token总价值
     * @notice  最后因为AggregatorV3Interface返回的 精度是 1e8 因为要同步精度，所有要 * 1e10 ，至于除以 1e18(PRECISION) ，可以当作为了把amount 转换成个数，比如 1个eth = 1e18 ， / 1e18(PRECISION) 为了把amount变为我们认为的个数也就是 “ 1 ”
     */
    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        (, int256 price,,,) = AggregatorV3Interface(s_priceFeeds[token]).latestRoundData();
        return (uint256(price) * 1e10 * amount) / PRECISION;
    }
}
