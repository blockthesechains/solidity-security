// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ReentrancyBankVulnerable
/// @notice INTENTIONALLY VULNERABLE — for education only. Do not deploy.
/// @dev The external call happens before the balance update, so a malicious
///      receiver can re-enter withdraw() and drain the contract.
contract ReentrancyBankVulnerable {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // VULNERABILITY: interaction happens BEFORE the state update
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State updated too late — reentrancy already drained funds
        balances[msg.sender] -= amount;
    }
}