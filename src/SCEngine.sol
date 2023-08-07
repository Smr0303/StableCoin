//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import {StableCoin} from "./Coin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/";

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
    error DSCEngine_TransferFailed();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    mapping(address token => address priceFeed) private s_priceFeeds; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DscMinted;
    address[] private s_collateralTokens;
    StableCoin private immutable i_dsc;

    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

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
            s_collateralTokens.push(tokenAddresses[i]);
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
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
    }

    /*
     * @title depositCollateral
     * @param tokenCollateralAddress : Collateral Address
     * @param amuntCollateral: Amount of token to be deposited
     */
    function depositCollateral() external {}

    function redeemCollateral() external {}

    /*
     * @notce follows CEI
     * @param amountDscToMint   : Amount
     * @notice they must have more collateral value then minimum threshold
     */

    function mintDsc(
        uint256 amountDscToMint
    ) external moreThanZero(amountDscToMint) {
        s_DscMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateralForDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /////////////////////////////////
    /////Internal Functions//////////
    /////////////////////////////////

    function _getAccountInformation(
        address user
    )
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DscMinted[user];
        collateralValueInUsd = getCollateralValue(user);
    }

    /*
     * @notice returns how close to liquidation the user is
     * If a user goes below 1 then they can get liquidated
     * @param user
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        return 
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        //Checks that do they have enough collateral
        //revert if they dont have
    }

    function getCollateralValue(
        address user
    ) public view returns (uint256 tokenCollateralValueInUsd) {
        //loop through each collateral token get the amount they have
        //the price to get usd value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amoount = s_collateralDeposited[user][token];
            tokenCollateralValueInUsd += getUsdValue(token, amoount);
        }
        return tokenCollateralValueInUsd;
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        Aggregatorv3Interface priceFeed = Aggregatorv3Interface[
            s_priceFeeds[token]
        ];
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return
            ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
