// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// LinearVest is a contract that releases tokens to a recipient linearly over a specified period.
// For example, if 100 tokens are vested over 100 days, the recipient will receive 1 token per day.
// However, the vesting happens every second, so every update to the block.timestamp means the amount
// withdrawable is updated. The contract should track the amount of tokens the user has withdrawn so far.
// For example, if the vesting period is 4 hours, then after 1 hour, 1/4th of the tokens are withdrawable.

// Be careful to track the amount withdrawn per-vesting. The same user might have multiple vestings using
// the same token.

// Lifecycle:
// Sender deposits tokens into the contracts and creates a vest
// Receiver can withdraw their tokens at any time, but only up to the amount released
// The receiver can identify vests that belong to them by scanning for events that contain
// their address as the recipient

contract LinearVest {

    using SafeERC20 for IERC20;

    struct Vest {
        address token;
        uint40 startTime;
        address recipient;
        uint40 duration;
        uint256 amount;
        uint256 withdrawn;
    }

    mapping(bytes32 => Vest) public vests;
    bytes32[] public vestIds;
    
    // Events
    event VestCreated(
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 duration
    );

    event VestWithdrawn(
        address indexed recipient,
        bytes32 indexed vestId,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    /*
     * @notice Creates a vest
     * @param token The token to vest
     * @param recipient The recipient of the vest
     * @param amount The amount of tokens to vest
     * @param startTime The start time of the vest in seconds
     * @param duration The duration of the vest in seconds
     * @param salt Allows for multiple vests to be created with the same parameters
     */
    function createVest(
        IERC20 token,
        address recipient,
        uint256 amount,
        uint40 startTime,
        uint40 duration,
        uint256 salt
    ) external {
        require(address(token) != address(0), "Invalid token");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(startTime >= block.timestamp, "Start time cannot be in the past");
        require(duration > 0, "Duration must be greater than 0");
        bytes32 vestId = computeVestId(token, recipient, amount, startTime, duration, salt);

        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == amount, "Fee-on-transfer not supported");
        
        vests[vestId] = Vest({
            token: address(token),
            startTime: startTime,
            recipient: recipient,
            duration: duration,
            amount: amount,
            withdrawn: 0
        });

        vestIds.push(vestId);

        emit VestCreated(msg.sender, recipient, address(token), amount, startTime, duration);

        // 1. Validate parameters (token, recipient, amount, startTime, duration)
        // 2. Generate vest ID
        // 3. Transfer tokens from sender to contract (with fee-on-transfer protection)
        // 4. Add vest to vests mapping
        // 5. Add vest ID to vestIds array
        // 6. Emit VestCreated event
    }

    /**
     * @notice Withdraws a vest
     * @param vestId The ID of the vest to withdraw
     * @param amount The amount to withdraw. If amount is greater than the amount withdrawable,
     * the amount withdrawable is withdrawn.
     */
    function withdrawVest(bytes32 vestId, uint256 amount) external {
        Vest memory vest = vests[vestId];
        require(vest.recipient != address(0), "Vest does not exist");
        require(vest.recipient == msg.sender, "Not the recipient");

        uint256 vestedAmount;
        if (block.timestamp < vest.startTime) {
            vestedAmount = 0;
        } else if (block.timestamp >= vest.startTime + vest.duration) {
            vestedAmount = vest.amount; // Fully vested
        } else {
            uint256 timeElapsed = block.timestamp - vest.startTime;
            vestedAmount = (vest.amount * timeElapsed) / vest.duration;
        }

        uint256 withdrawableAmount = vestedAmount - vest.withdrawn;
        require(withdrawableAmount > 0, "No tokens available for withdrawal");


        if (amount > withdrawableAmount) amount = withdrawableAmount;  

        vests[vestId].withdrawn += amount;

        

        IERC20(vest.token).safeTransfer(msg.sender, amount);


        emit VestWithdrawn(msg.sender, vestId, address(vest.token), amount, block.timestamp);

        // 1. Check vest exists
        // 2. Check msg.sender is the recipient
        // 3. Calculate how much has vested so far (time-based linear calculation)
        // 4. Calculate how much can be withdrawn (vested - already withdrawn)
        // 5. Cap withdrawal amount to available amount
        // 6. Update withdrawn amount (CEI pattern)
        // 7. Transfer tokens to recipient
        // 8. Emit VestWithdrawn event
    }

    /*
     * @notice Computes the vest ID for a given vest
     * @param token The token to vest
     * @param recipient The recipient of the vest
     * @param amount The amount of tokens to vest
     * @param startTime The start time of the vest in seconds
     * @param duration The duration of the vest in seconds
     * @param salt Allows for multiple vests to be created with the same parameters
     * @return The vest ID, which is the keccak256 hash of the vest parameters
     */
    function computeVestId(
        IERC20 token,
        address recipient,
        uint256 amount,
        uint40 startTime,
        uint40 duration,
        uint256 salt
    ) public pure returns (bytes32) {
        bytes memory encoded = abi.encode(token, recipient, amount, startTime, duration, salt);
        return keccak256(encoded);
        // 1. Encode all parameters (including salt for uniqueness)
        // 2. Return keccak256 hash as unique vest ID
    }
}
