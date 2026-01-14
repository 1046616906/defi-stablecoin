// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
// import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Validations} from "../utils/Validations.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";

/**
 * @title DSCEngine
 * @author Noah Harrison
 * @notice this is a study object
 */

contract DSCEngine is Validations {
    error DSCEngine__TokenAddressesAndpriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();

    modifier isAllowedToken(address _token) {
        _isAllowedToken(_token);
        _;
    }

    function _isAllowedToken(address _token) internal view {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
    }

    mapping(address => address) private s_priceFeeds;
    mapping(address => mapping(address => uint256)) s_tokenAddressToUser;
    DecentralizedStableCoin immutable i_dsc;

    constructor(address[] memory tokenAddress, address[] memory priceFeedsAddress, address dscAddress) {
        if (tokenAddress.length != priceFeedsAddress.length) {
            revert DSCEngine__TokenAddressesAndpriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i]] = priceFeedsAddress[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /* 存入抵押并且铸造DSC */
    function depositCollateralAndMintDsc() external {}

    /* 只存入抵押品 不铸造 DSC ，因为铸造会影响 健康值  health factor */
    function depositCollateral(address tokenCollateralAddress, uint256 tokenAmount)
        external
        moreThanZero(tokenAmount)
    {}

    /* 铸造Dsc */
    function mintDes() external {}

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
}
