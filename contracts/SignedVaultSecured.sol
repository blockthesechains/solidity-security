// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title SignedVaultSecured
/// @notice Secure version. Three layered defenses against signature replay:
///         1. Per-user nonce        — each signature is single-use
///         2. EIP-712 domain sep.    — binds signatures to this contract + chain
///         3. OZ ECDSA.recover       — rejects malformed / malleable signatures
contract SignedVaultSecured is EIP712 {
    address public owner;
    mapping(address => uint256) public nonces;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(address recipient,uint256 amount,uint256 nonce)");

    constructor(address _owner) payable EIP712("SignedVault", "1") {
        owner = _owner;
    }

    /// @notice The exact digest the owner must sign for a given claim.
    ///         Exposed so off-chain signers (and tests) sign precisely what
    ///         the contract verifies.
    function hashToSign(address recipient, uint256 amount, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(abi.encode(CLAIM_TYPEHASH, recipient, amount, nonce))
        );
    }

    function claim(uint256 amount, bytes calldata signature) external {
        uint256 nonce = nonces[msg.sender];
        bytes32 digest = hashToSign(msg.sender, amount, nonce);

        address signer = ECDSA.recover(digest, signature);
        require(signer == owner, "invalid signature");

        // EFFECT first: consume the nonce before the external call.
        nonces[msg.sender] = nonce + 1;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
    }

    receive() external payable {}
}
