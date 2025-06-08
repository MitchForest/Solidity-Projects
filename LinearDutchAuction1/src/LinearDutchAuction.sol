// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// If someone wants to sell a token, they create a dutch auction using the linear dutch auction factory.
// In a single transaction, the factory creates the auction and the token is transferred from the user to the auction.
contract LinearDutchAuctionFactory {
    using SafeERC20 for IERC20;
    event AuctionCreated(address indexed auction, address indexed token, uint256 startingPriceEther, uint256 startTime, uint256 duration, uint256 amount, address seller);

    function createAuction(
        IERC20 _token,
        uint256 _startingPriceEther,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount,
        address _seller
    ) external returns (address) {

        if (_token == IERC20(address(0))) revert("Token cannot be 0");
        if (_startingPriceEther == 0) revert("Starting price cannot be 0");
        if (_duration == 0) revert("Duration cannot be 0");
        if (_startTime < block.timestamp) revert("Start time cannot be in the past");
        if (_seller == address(0)) revert("Seller cannot be 0");

        LinearDutchAuction auction = new LinearDutchAuction(_token, _startingPriceEther, _startTime, _duration, _seller);
        _token.safeTransferFrom(msg.sender, address(auction), _amount);
        emit AuctionCreated(address(auction), address(_token), _startingPriceEther, _startTime, _duration, _amount, _seller);
        return address(auction);

        // 1. Validate input parameters (token != 0, price > 0, duration > 0, startTime >= now, seller != 0)
        // 2. Create new LinearDutchAuction contract with parameters
        // 3. Transfer tokens from msg.sender to the new auction contract
        // 4. Emit AuctionCreated event with auction address and parameters
        // 5. Return auction address
    }
}

// The auction is a contract that sells the token at a decreasing price until the duration is over.
// The price starts at `startingPriceEther` and decreases linearly to 0 over the `duration`.
// Someone can buy the token at the current price by sending ether to the auction.
// The auction will try to refund the user if they send too much ether.
// The contract directly sends the Ether to the `seller` and does not hold any ether.
// If the price goes to zero, anyone can claim the tokens by calling the contract with msg.value = 0
contract LinearDutchAuction {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable startingPriceEther;
    uint256 public immutable startTime;
    uint256 public immutable durationSeconds;
    address public immutable seller;

    error AuctionNotStarted();
    error MsgValueInsufficient();
    error SendEtherToSellerFailed();

    /*
     * @notice Constructor
     * @param _token The token to sell
     * @param _startingPriceEther The starting price of the token in Ether
     * @param _startTime The start time of the auction.
     * @param _duration The duration of the auction. In seconds
     * @param _seller The address of the seller
     */
    constructor(
        IERC20 _token,
        uint256 _startingPriceEther,
        uint256 _startTime,
        uint256 _durationSeconds,
        address _seller
    ) {
        token = _token;
        startingPriceEther = _startingPriceEther;
        startTime = _startTime;
        durationSeconds = _durationSeconds;
        seller = _seller;

        // 1. Set all immutable variables (token, startingPriceEther, startTime, durationSeconds, seller)
    }

    /*
     * @notice Get the current price of the token
     * @dev Returns 0 if the auction has ended
     * @revert if the auction has not started yet
     * @revert if someone already purchased the token
     * @return the current price of the token in Ether
     */ 
    function currentPrice() public view returns (uint256) {
        if (block.timestamp < startTime) revert AuctionNotStarted();
        if (block.timestamp >= startTime + durationSeconds) return 0;
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 priceReduction = (timeElapsed * startingPriceEther) / durationSeconds;
        return startingPriceEther - priceReduction;

        // 1. Check if auction has started (block.timestamp >= startTime)
        // 2. Check if auction has ended (block.timestamp >= startTime + duration)
        // 3. If ended, return 0
        // 4. Calculate time elapsed since start
        // 5. Calculate price reduction: (timeElapsed * startingPrice) / duration
        // 6. Return startingPrice - priceReduction
    }

    /*
     * @notice Buy tokens at the current price
     * @revert if the auction has not started yet
     * @revert if the auction has ended
     * @revert if the user sends too little ether for the current price
     * @revert if sending Ether to the seller fails
     * @dev Will try to refund the user if they send too much ether. If the refund reverts, the transaction still succeeds.
     */
    receive() external payable {
        uint256 currentPrice = currentPrice();
        if (msg.value < currentPrice) revert MsgValueInsufficient();
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        payable(seller).transfer(currentPrice);
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }
        // 1. Check auction has started
        // 2. Get current price
        // 3. Check msg.value >= currentPrice
        // 4. Transfer all tokens to buyer
        // 5. Send currentPrice ETH to seller (revert if fails)
        // 6. Try to refund excess ETH to buyer (don't revert if fails)
    }
}
