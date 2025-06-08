// SPDX-License-Identifier: (c) RareSkills
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Crowdfunding {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline;

    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event CancelContribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed beneficiary, uint256 amount);

    constructor(address token_, address beneficiary_, uint256 fundingGoal_, uint256 deadline_) {

        if (token_ == address(0)) revert("Token address cannot be 0");
        if (beneficiary_ == address(0)) revert("Beneficiary address cannot be 0");
        if (fundingGoal_ == 0) revert("Funding goal must be greater than 0");
        if (deadline_ <= block.timestamp) revert("Deadline must be in the future");

        token = IERC20(token_);
        beneficiary = beneficiary_;
        fundingGoal = fundingGoal_;
        deadline = deadline_;
        // 1. Validate all parameters (no zero addresses, goal > 0, deadline in future)
        // 2. Set all immutable variables
    }

    /*
     * @notice a contribution can be made if the deadline is not reached.
     * @param amount the amount of tokens to contribute.
     */
    function contribute(uint256 amount) external {
        if (block.timestamp > deadline) revert("Contribution period over");
        token.safeTransferFrom(msg.sender, address(this), amount);
        contributions[msg.sender] += amount;
        emit Contribution(msg.sender, amount);
        // 1. Check deadline not passed
        // 2. Transfer tokens from contributor to contract
        // 3. Update contributions mapping
        // 4. Emit Contribution event
    }

    /*
     * @notice a contribution can be cancelled if the goal is not reached. Returns the tokens to the contributor.
     */ 
    function cancelContribution() external {
        if (token.balanceOf(address(this)) >= fundingGoal) revert("Cannot cancel after goal reached");
        if (contributions[msg.sender] == 0) revert("No contribution to cancel");
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
        emit CancelContribution(msg.sender, amount);
        // 1. Check funding goal not reached
        // 2. Check contributor has contribution to cancel
        // 3. Get contributor's contribution amount
        // 4. Reset contribution to 0
        // 5. Transfer tokens back to contributor
        // 6. Emit CancelContribution event
    }

    /*
     * @notice the beneficiary can withdraw the funds if the goal is reached.
     */
    function withdraw() external {
        if (msg.sender != beneficiary) revert("Only beneficiary can withdraw");
        if (block.timestamp < deadline) revert("Funding period not over");
        if (token.balanceOf(address(this)) < fundingGoal) revert("Funding goal not reached");
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(beneficiary, amount);
        emit Withdrawal(beneficiary, amount);
        // 1. Check caller is beneficiary
        // 2. Check deadline has passed
        // 3. Check funding goal reached
        // 4. Store contract balance amount
        // 5. Transfer all contract tokens to beneficiary
        // 6. Emit Withdrawal event
    }
}
