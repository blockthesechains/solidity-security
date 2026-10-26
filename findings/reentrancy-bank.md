# Audit Findings — ReentrancyBank

An audit of `ReentrancyBankVulnerable.sol`, a simple ETH vault where users deposit and withdraw their own balance. A single reentrancy flaw lets any depositor drain the entire contract — every other user's funds included.

## Summary

| # | Finding | Severity |
|---|---------|----------|
| 1 | Reentrancy in `withdraw()` drains all contract funds | Critical |

Root cause: **`withdraw()` sends ETH to the caller *before* reducing the caller's recorded balance**, so a malicious receiver can re-enter `withdraw()` while its balance still reads as unspent. This is the same class of bug behind The DAO hack (2016).

---

## Finding 1 — Reentrancy in `withdraw()`

**Severity:** Critical

**Root cause:** The external call precedes the state update (violates Checks-Effects-Interactions):

```solidity
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // INTERACTION happens before the EFFECT
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    // State updated too late — the re-entrant calls already ran
    balances[msg.sender] -= amount;
}
```

When `call` transfers ETH to a contract, it hands execution to that contract's `receive()`/`fallback`. At that moment `balances[msg.sender]` has **not** yet been decremented, so the `require(balances[msg.sender] >= amount)` check passes again on a nested call.

**Preconditions:** Attacker controls a contract and can make one deposit. No special privileges, no capital beyond the first stake.

**Attack:**
1. Attacker deposits a small stake (e.g. 1 ETH) into a bank already holding other users' funds (e.g. 10 ETH).
2. Attacker calls `withdraw(1 ether)`.
3. The bank sends 1 ETH to the attacker **before** decrementing the balance.
4. The transfer triggers the attacker's `receive()`, which calls `withdraw(1 ether)` again — the balance check still passes because the decrement hasn't run.
5. Steps 3–4 repeat until the bank is empty. The queued `-=` operations unwind afterward, but the ETH is already gone.

**Impact:** Total loss of all contract funds. A depositor staking 1 ETH against a 10 ETH bank walks away with the full 11 ETH. Confirmed by proof-of-concept: starting balance `bank = 11 ETH` ends `bank = 0`, attacker contract holds `11 ETH`.

---

## Recommendation

Apply **Checks-Effects-Interactions** — update state before the external call — and add a reentrancy lock as defense-in-depth. Both are implemented in `ReentrancyBankSecured.sol`:

```solidity
function withdraw(uint256 amount) external nonReentrant {
    // CHECKS
    require(amount > 0, "Must withdraw more than zero");
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // EFFECTS — state updated before any external call
    balances[msg.sender] -= amount;

    // INTERACTIONS — external call happens last
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

**Why this works:**
- With the balance decremented *first*, a re-entrant call reads the reduced balance and reverts at `require(balances[msg.sender] >= amount)`. The attacker can never withdraw more than it deposited.
- OpenZeppelin's `ReentrancyGuard` (`nonReentrant`) independently reverts any nested entry, covering attackers that try to force re-entry regardless.

See `ReentrancyBankSecured.t.sol` for the test: a probe deposits 1 ETH and attempts to re-enter `withdraw()` during its refund. The reentry is attempted but blocked — the attacker recovers only its own 1 ETH, and the victim's 10 ETH stays safe.

---

## References

- SWC-107: Reentrancy — https://swcregistry.io/docs/SWC-107
- OpenZeppelin `ReentrancyGuard`
- Checks-Effects-Interactions — Solidity documentation
