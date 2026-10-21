// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title RewardPoolSecured
/// @notice Rewards accrue based on how much you had staked WHEN rewards were
///         added — not your instantaneous share at claim time. Defeats both the
///         infinite-claim bug and the flash-loan stake attack.
contract RewardPoolSecured is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public totalStaked;
    mapping(address => uint256) public staked;

    uint256 public rewardPerTokenStored;                 // scaled by 1e18
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private constant PRECISION = 1e18;

    error NothingStaked();
    error ZeroAmount();
    error InsufficientStake();
    error NoRewards();

    constructor(IERC20 _token) { token = _token; }

    modifier updateReward(address account) {
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function earned(address account) public view returns (uint256) {
        uint256 accrued = (staked[account] *
            (rewardPerTokenStored - userRewardPerTokenPaid[account])) / PRECISION;
        return rewards[account] + accrued;
    }

    function addRewards(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (totalStaked == 0) revert NothingStaked();
        token.safeTransferFrom(msg.sender, address(this), amount);
        rewardPerTokenStored += (amount * PRECISION) / totalStaked;
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert ZeroAmount();
        token.safeTransferFrom(msg.sender, address(this), amount);
        staked[msg.sender] += amount;
        totalStaked += amount;
    }

    function unstake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert ZeroAmount();
        if (staked[msg.sender] < amount) revert InsufficientStake();
        staked[msg.sender] -= amount;
        totalStaked -= amount;
        token.safeTransfer(msg.sender, amount);
    }

    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NoRewards();
        rewards[msg.sender] = 0;
        token.safeTransfer(msg.sender, reward);
    }
}