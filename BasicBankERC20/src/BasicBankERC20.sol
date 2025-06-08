// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Create a Basic Bank that allows the user to deposit and withdraw any ERC20 token
// Disallow any fee on transfer tokens
contract BasicBankERC20 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    error FeeOnTransferNotSupported();
    error InsufficientBalance();
    error InsufficientAllowance();

    mapping(address => mapping(address => uint256)) public userTokenBalance;

    /*
     * @notice Deposit any ERC20 token into the bank
     * @dev reverts with FeeOnTransferNotSupported if the token is a fee on transfer token
     * @param token The address of the token to deposit
     * @param amount The amount of tokens to deposit
     */
    function deposit(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        IERC20 tokenInstance =IERC20(token);
        uint256 userBalance = tokenInstance.balanceOf(msg.sender);
        require(userBalance >= amount, InsufficientBalance());
        require(amount <= tokenInstance.allowance(msg.sender, address(this)), InsufficientAllowance());

        uint256 bankBalanceBefore = tokenInstance.balanceOf(address(this));
        tokenInstance.safeTransferFrom(msg.sender, address(this), amount);
        uint256 bankBalanceAfter = tokenInstance.balanceOf(address(this));
        require(bankBalanceAfter - bankBalanceBefore == amount, FeeOnTransferNotSupported());
       
        userTokenBalance[msg.sender][token] += amount;
        emit Deposit(msg.sender, token, amount);
        // make sure amount is greater than 0
        // make sure user has enough balance
        // check for fee on transfer tokens by comparing bankBalanceBefore and bankBalanceAfter
        // transfer tokens from user to bank
        // update userTokenBalance
        // emit Deposit event
    }

    /*
     * @notice Withdraw any ERC20 token from the bank
     * @dev reverts with InsufficientBalance() if the user does not have enough balance
     * @param token The address of the token to withdraw
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(address token, uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than 0");
        IERC20 tokenInstance =IERC20(token);
        require(userTokenBalance[msg.sender][token] >= amount, InsufficientBalance());
        uint256 bankBalance = tokenInstance.balanceOf(address(this));
        require(bankBalance >= amount, InsufficientBalance());
        userTokenBalance[msg.sender][token] -= amount;
        tokenInstance.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, token, amount);
        // make sure amount is greater than 0
        // make sure user has enough balance in bank
        // make sure bank has enough balance
        // update userTokenBalance (before transfer)
        // transfer tokens from bank to user
        // emit Withdraw event
    }
}

/*
Note I added the ReentrancyGuard to deposit, but not withdraw,
b/c withdraw implements the checks-effects-interaction pattern
while deposit requires checking for fee-transfer tokens before updating state
*/