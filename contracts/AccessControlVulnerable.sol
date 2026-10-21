// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AccessControlVulnerable
/// @notice INTENTIONALLY VULNERABLE — for education only. Do not deploy.
/// @dev `withdrawAll` has no owner check, so ANY address can drain the funds.
contract AccessControlVulnerable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {}

    // VULNERABILITY: no access control — anyone can call this and drain it.
    function withdrawAll() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}