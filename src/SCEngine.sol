//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import {StableCoin} from "./Coin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Engine for Stable Coin
 * @author Samarjeet Mohite
 * @notice It handles all the logic of minting , burning coins , as well as depositing and withdrawing coins
 * @notice Contract is very loosely based on MakerDao
 */
contract SCEngine is ReentrancyGuard {
    error DscEngine_NeedsMoreThanZero();
    error DscEngine_TokenAddressAndPriceFeedAddressesMustBeSameLength();
    error DscEngine_NotAllowedToken();

    mapping(address token => address priceFeed) private s_priceFeeds; //tokenToPriceFeed
    mapping(address user =>mapping(address token => uint256 amount)) s_collateralDeposited;
    StableCoin private immutable i_dsc;

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DscEngine_NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DscEngine_NotAllowedToken();
        }
        _;
    }

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DscEngine_TokenAddressAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = StableCoin(dscAddress);
    }

    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        payable
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {}

    /*
     * @title depositCollateral
     * @param tokenCollateralAddress : Collateral Address
     * @param amuntCollateral: Amount of token to be deposited
     */
    function depositCollateral() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function redeemCollateralForDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
