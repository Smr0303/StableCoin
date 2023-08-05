//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 *@titile Decentralised Stable Coin
 *@author Samarjeet Mohite
 *Collateral Exogeneous
 * Minting Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This contract will be governed by SCEngine.sol, this is just the ERC20 implementation of coin
 */
contract StableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin_Must_Be_More_Than_Zero();
    error DecentralizedStableCoin_Burn_Amount_Exceeds_Balance();
    error DecentralizedStableCoin_NotZeroAddress();

    constructor() ERC20("StableCoin", "SC") {}

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin_NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin_Must_Be_More_Than_Zero();
        }
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public override {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin_Must_Be_More_Than_Zero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin_Burn_Amount_Exceeds_Balance();
        }

        super.burn(_amount);
    }
}
