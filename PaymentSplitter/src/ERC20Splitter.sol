// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Splitter {

    using SafeERC20 for IERC20;

    error InsufficientBalance();
    error InsufficientApproval();
    error ArrayLengthMismatch();

    function split(IERC20 token, address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, ArrayLengthMismatch());
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(token.balanceOf(msg.sender) >= totalAmount, InsufficientBalance());
        require(token.allowance(msg.sender, address(this)) >= totalAmount, InsufficientApproval());

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], amounts[i]);
        }


        // 1. Check arrays have same length
        // 2. Calculate total amount needed (sum all amounts)
        // 3. Check msg.sender has enough balance for total amount
        // 4. Check msg.sender has given this contract enough allowance for total amount
        // 5. Loop through recipients and transferFrom msg.sender to each recipient
    }
}
