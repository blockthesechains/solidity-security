// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ReentrancyBankSecured
/// @notice Secure version. Two layered defenses against reentrancy:
///         1. Checks-Effects-Interactions — state updated BEFORE the call
///         2. ReentrancyGuard (nonReentrant) — blocks nested calls as a backstop
contract ReentrancyBankSecured is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than zero");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        // CHECKS
        require(amount > 0, "Must withdraw more than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // EFFECTS — update state before any external call
        balances[msg.sender] -= amount;

        // INTERACTIONS — external call happens last
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}