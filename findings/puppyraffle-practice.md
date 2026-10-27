# Practice Audit — PuppyRaffle

A self-directed training audit of `PuppyRaffle.sol`, an intentionally-vulnerable raffle contract from Cyfrin's security curriculum. Players pay an entrance fee, a winner is drawn for a prize + NFT, and the owner takes a fee cut.

> **Note:** PuppyRaffle is public teaching material and these vulnerabilities are documented course content — this write-up is a practice pass to demonstrate methodology and range across bug classes, not a claim of novel discovery. Pragma: `^0.7.6` (pre-0.8, no built-in overflow checks).

## Summary

| # | Finding | Severity |
|---|---------|----------|
| 1 | Reentrancy in `refund()` drains the prize pool | High |
| 2 | Predictable randomness in `selectWinner()` lets the outcome be gamed | High |
| 3 | Unsafe `uint64` cast + pre-0.8 overflow corrupts fee accounting | Medium |
| 4 | O(n²) duplicate check enables denial-of-service | Medium |

---

## Finding 1 — Reentrancy in `refund()`

**Severity:** High

**Root cause:** The refund sends ETH before clearing the player slot (violates Checks-Effects-Interactions):

```solidity
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "Only the player can refund");
    require(playerAddress != address(0), "Player already refunded, or is not active");

    payable(msg.sender).sendValue(entranceFee);   // INTERACTION first
    players[playerIndex] = address(0);             // EFFECT too late
    emit RaffleRefunded(playerAddress);
}
```

**Attack:** An attacker enters via a contract with a `receive()`/`fallback`, then calls `refund()`. The `sendValue` transfer hands control back to the attacker *before* `players[playerIndex]` is zeroed, so the attacker re-enters `refund()` — the `require(playerAddress != address(0))` check still passes — and pulls another `entranceFee`. The loop repeats until the contract is drained.

**Impact:** Total theft of the raffle pool (every other player's entrance fees).

**Recommendation:** Apply CEI — zero `players[playerIndex]` *before* `sendValue`. Add OpenZeppelin's `nonReentrant` modifier as defense-in-depth.

---

## Finding 2 — Predictable randomness in `selectWinner()`

**Severity:** High

**Root cause:** The winner is derived from on-chain values that are known (or influenceable) at call time:

```solidity
uint256 winnerIndex =
    uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty))) % players.length;
```

**Attack:** Every input (`msg.sender`, `block.timestamp`, `block.difficulty`/`prevrandao`) is readable before the transaction executes. Any caller can **precompute `winnerIndex` off-chain** and only call `selectWinner()` when it resolves in their favor — or wrap the call in a contract that reverts if they would lose. A miner/validator can go further and manipulate `block.timestamp`/`prevrandao` to force a result.

**Impact:** The raffle is riggable; the "winner" is not fair or unpredictable. The prize can be captured on demand.

**Recommendation:** Use a verifiable randomness source — Chainlink VRF — so the result cannot be predicted or influenced by the caller or block proposer.

---

## Finding 3 — Unsafe `uint64` cast + pre-0.8 overflow on fees

**Severity:** Medium

**Root cause:** `totalFees` is a `uint64`, and fees are accumulated with both an unsafe downcast and unchecked addition:

```solidity
uint64 public totalFees = 0;
...
totalFees = totalFees + uint64(fee);   // fee is uint256
```

Two distinct problems in one line:
- **Downcast truncation:** `uint64(fee)` silently truncates if `fee > type(uint64).max` (~18.44 ETH). Explicit casts **never revert — even in Solidity 0.8.x** — so upgrading the compiler does *not* fix this.
- **Addition overflow:** under `^0.7.6` the `+` wraps silently with no revert (this specific issue *is* fixed by 0.8's checked arithmetic).

**Impact:** `totalFees` can be corrupted. `withdrawFees()` gates on `require(address(this).balance == uint256(totalFees))`, so once the accounting is wrong, legitimate fees can become **permanently stuck**.

**Recommendation:** Store `totalFees` as `uint256`, compile with Solidity ≥ 0.8 for checked arithmetic, and use OpenZeppelin `SafeCast` for any necessary downcasts.

---

## Finding 4 — O(n²) duplicate check enables denial-of-service

**Severity:** Medium

**Root cause:** `enterRaffle()` checks for duplicates with a nested loop over the entire `players` array:

```solidity
for (uint256 i = 0; i < players.length - 1; i++) {
    for (uint256 j = i + 1; j < players.length; j++) {
        require(players[i] != players[j], "Duplicate player");
    }
}
```

**Attack:** Cost grows quadratically with `players.length`. An attacker can bloat the array cheaply early on (`enterRaffle` accepts an array, so many entrants can be added in one transaction). Once the array is large enough, the duplicate-check loop exceeds the block gas limit and every subsequent `enterRaffle()` call reverts — locking out all future participants and stalling the raffle.

**Impact:** Denial-of-service on a core function. Even without a malicious actor, gas is unfair: early entrants pay little, late entrants pay escalating amounts.

**Recommendation:** Track entrants in a `mapping` (e.g. `mapping(address => bool)` or an `addressToRaffleId` mapping) for **O(1)** duplicate detection instead of the nested loop.

---

## References

- SWC-107 (Reentrancy), SWC-120 (Weak randomness), SWC-101 (Integer overflow/underflow), SWC-128 (DoS with block gas limit)
- OpenZeppelin `ReentrancyGuard`, `SafeCast`
- Chainlink VRF documentation
