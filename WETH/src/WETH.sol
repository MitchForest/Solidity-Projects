// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20("Wrapped Ether", "WETH") {


    function deposit() external payable {
        _mint(msg.sender, msg.value);
        // Mint WETH tokens to user
    }

    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
        // Check user has enough balance
        // Check contract has enough balance
        // Burn WETH tokens from user
        // Send ETH to user (call{value: amount} msg.sender)
    }

}
