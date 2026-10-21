// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AccessControlSecured
/// @notice Fixed version: only the owner can withdraw, via OpenZeppelin's Ownable.
contract AccessControlSecured is Ownable {
    constructor() Ownable(msg.sender) {}

    function deposit() external payable {}

    function withdrawAll() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}