// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title RewardPoolVulnerable
/// @notice INTENTIONALLY VULNERABLE — for education only. Do not deploy.
/// @dev Rewards pay out on the caller's INSTANTANEOUS share at claim time, and
///      nothing tracks what's already been claimed. Enables (1) repeated claims
///      of the same stake and (2) a flash-loan stake capturing ~the whole pool.
contract RewardPoolVulnerable {
    IERC20 public immutable token;
    uint256 public rewardBalance;
    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    constructor(IERC20 _token) { token = _token; }

    function addRewards(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        rewardBalance += amount;
    }
    function stake(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        staked[msg.sender] += amount;
        totalStaked += amount;
    }
    function claimReward() external {
        uint256 share = (rewardBalance * staked[msg.sender]) / totalStaked;
        rewardBalance -= share;
        token.transfer(msg.sender, share);
    }
    function unstake(uint256 amount) external {
        staked[msg.sender] -= amount;
        totalStaked -= amount;
        token.transfer(msg.sender, amount);
    }
}