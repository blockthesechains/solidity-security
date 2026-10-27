# 03 — Truster

**Class:** Arbitrary external call · **Impact:** full drain

## Target
A flash-loan pool holding 1,000,000 DVT.

## The bug
`flashLoan` makes an attacker-controlled call *as the pool*:
```solidity
token.transfer(borrower, amount);
target.functionCall(data);     // any target, any data, executed as the pool
```

## The exploit
Flash-loan `amount = 0` (so the repayment check passes trivially) with `target = token`, `data = approve(attacker, max)`. The pool approves the attacker to spend its own tokens. The attacker then `transferFrom`s the full 1,000,000 DVT to recovery — all in one deployed contract (one tx).

## The fix
Never let untrusted input control both the `target` and the `data` of a call the contract makes. A flash lender has no reason to make arbitrary external calls.
