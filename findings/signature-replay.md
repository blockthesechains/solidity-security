# Audit Findings — SignedVault (Signature Replay)

An audit of `SignedVaultVulnerable.sol`, a vault that releases ETH when the owner has signed off on a withdrawal (a common pattern for airdrops, gasless claims, and meta-transactions). A single valid signature can be replayed to drain the vault.

## Summary

| # | Finding | Severity |
|---|---------|----------|
| 1 | Signature replay — one valid signature drains the vault | High |

Root cause: **the contract verifies the owner's signature but never marks it used, and never binds it to this contract or chain.** A signature authorizing one withdrawal authorizes unlimited identical withdrawals.

---

## Finding 1 — Signature replay in `claim()`

**Severity:** High

**Root cause:** The signed message contains no nonce and no domain separator:

```solidity
function claim(uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount));
    address signer = ecrecover(hash, v, r, s);
    require(signer == owner, "invalid signature");

    (bool ok, ) = msg.sender.call{value: amount}("");
    require(ok, "transfer failed");
}
```

Nothing records that a given signature has been consumed, so the `require(signer == owner)` check passes on every repeat.

**Important distinction — this is replay, not reentrancy.** Reentrancy re-enters a function *within a single transaction* via an external callback before state settles. Replay reuses the same authorization across *separate, independent transactions*. The fix is different: reentrancy is solved by CEI ordering / a guard; replay is solved by making each authorization single-use.

**Preconditions:** Attacker holds one valid owner signature for `(attacker, amount)` — e.g. a legitimate claim they were granted.

**Attack:**
1. Owner signs off that the attacker may withdraw `amount` (intended: once).
2. Attacker calls `claim(amount, v, r, s)` — receives `amount`.
3. Attacker calls `claim` again with the **same** `(v, r, s)`. The hash is identical, the signature still recovers to `owner`, the check passes, and another `amount` is sent.
4. Repeat until the vault is empty.

**Impact:** Total loss of vault funds. A one-time authorization becomes an unlimited withdrawal. Confirmed by PoC: owner authorizes 1 ETH once, attacker replays the signature 5× and drains a 5 ETH vault to 0.

**Secondary exposure:** Because the hash omits `address(this)` and `chainid`, the same signature is also valid on any identical contract (cross-contract replay) and on every chain the contract is deployed to (cross-chain replay).

---

## Recommendation

Make every signature single-use and bind it to this contract and chain. Implemented in `SignedVaultSecured.sol` with three layers:

1. **Per-user nonce** — include `nonces[msg.sender]` in the signed data and increment it on each claim, so a signature works exactly once.
2. **EIP-712 domain separation** — sign structured data under a domain that includes the contract name, version, `chainid`, and `address(this)`, defeating cross-contract and cross-chain replay.
3. **OpenZeppelin `ECDSA.recover`** — instead of raw `ecrecover`, rejecting malformed and malleable (high-`s`) signatures and the `address(0)` recovery edge case.

```solidity
function claim(uint256 amount, bytes calldata signature) external {
    uint256 nonce = nonces[msg.sender];
    bytes32 digest = hashToSign(msg.sender, amount, nonce); // EIP-712 typed digest
    address signer = ECDSA.recover(digest, signature);
    require(signer == owner, "invalid signature");

    nonces[msg.sender] = nonce + 1; // consume before the external call
    (bool ok, ) = msg.sender.call{value: amount}("");
    require(ok, "transfer failed");
}
```

**Fix verification (`SignedVault.t.sol`):** against the secured vault, the first claim succeeds for the authorized 1 ETH; replaying the identical signature reverts (`invalid signature`) because the nonce has advanced and the digest no longer matches. The attacker keeps only the 1 ETH they were actually granted; the remaining 4 ETH stays in the vault.

---

## References

- SWC-121: Missing protection against signature replay
- EIP-712: Typed structured data hashing and signing
- EIP-2: Homestead (signature malleability / low-`s` requirement)
- OpenZeppelin `ECDSA`, `EIP712`
