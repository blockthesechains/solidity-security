// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SignedVaultVulnerable
/// @notice INTENTIONALLY VULNERABLE — for education only. Do not deploy.
/// @dev Verifies an owner signature authorizing a withdrawal, but tracks no
///      nonce and has no domain separation, so a SINGLE valid signature can be
///      replayed indefinitely to drain the vault.
contract SignedVaultVulnerable {
    address public owner;

    constructor(address _owner) payable {
        owner = _owner;
    }

    function claim(uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        // No nonce, no domain separator — nothing marks this signature "used".
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount));
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "invalid signature");

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
    }

    receive() external payable {}
}
