// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// tokenA and tokenB are stablecoins, so they have the same value, but different
// decimals. This contract allows users to trade one token for another at equal rate
// after correcting for the decimals difference 
contract DecimalSwap {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable tokenA;
    IERC20Metadata public immutable tokenB;

    constructor(address tokenA_, address tokenB_) {
        tokenA = IERC20Metadata(tokenA_);
        tokenB = IERC20Metadata(tokenB_);
    }

    function swapAtoB(uint256 amountIn) external {
        require(tokenA.balanceOf(msg.sender) >= amountIn, "Insufficient balance");
        require(tokenA.allowance(msg.sender, address(this)) >= amountIn, "Insufficient allowance");

        uint256 decimalsA = tokenA.decimals();
        uint256 decimalsB = tokenB.decimals();
        uint256 amountOut = amountIn * (10 ** decimalsB) / (10 ** decimalsA);

        require(tokenB.balanceOf(address(this)) >= amountOut, "Insufficient balance");

        tokenA.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenB.safeTransfer(msg.sender, amountOut);

        // 1. Check msg.sender has enough balance of tokenA
        // 2. Check msg.sender and contract have enough allowance of tokenA
        // 3. Calculate amountOut (amountOut = amountIn * (10^decimalsB) / (10^decimalsA))
        // 4. Check contract has enough balance of tokenB
        // 5. Transfer tokenA from msg.sender to contract
        // 6. Transfer tokenB from contract to msg.sender
    }

    function swapBtoA(uint256 amountIn) external {
        require(tokenB.balanceOf(msg.sender) >= amountIn, "Insufficient balance");
        require(tokenB.allowance(msg.sender, address(this)) >= amountIn, "Insufficient allowance");

        uint256 decimalsA = tokenA.decimals();
        uint256 decimalsB = tokenB.decimals();
        uint256 amountOut = amountIn * (10 ** decimalsA) / (10 ** decimalsB);

        require(tokenA.balanceOf(address(this)) >= amountOut, "Insufficient balance");

        tokenB.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenA.safeTransfer(msg.sender, amountOut);

        // 0. Calculate decimals difference
        // 1. Check msg.sender has enough balance of tokenB
        // 2. Check msg.sender and contract have enough allowance of tokenB
        // 3. Calculate amountOut (amountOut = amountIn * (10^decimalsA) / (10^decimalsB))
        // 4. Check contract has enough balance of tokenA
        // 5. Transfer tokenB from msg.sender to contract
        // 6. Transfer tokenA from contract to msg.sender
    }
}
