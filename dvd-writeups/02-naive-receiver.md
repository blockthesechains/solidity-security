# 02 — Naive Receiver

**Class:** Flash-loan fee griefing + meta-transaction sender spoofing · **Impact:** full drain

## Target
A pool charging a flat 1 WETH flash-loan fee, a "naive" receiver holding 10 WETH, a trusted forwarder (meta-tx relayer), and a multicall.

## The bugs
1. **Anyone can trigger a flash loan naming any receiver**, and the receiver blindly repays loan + fee. Ten loans drain its 10 WETH into the pool (credited to the deployer).
2. The pool's `_msgSender()` trusts the **last 20 bytes of calldata** when the call arrives via the forwarder (ERC-2771 pattern):
```solidity
if (msg.sender == trustedForwarder && msg.data.length >= 20)
    return address(bytes20(msg.data[msg.data.length - 20:]));
```

## The exploit
Batch into one `multicall` (one signed forwarder request = one tx): 10 flash loans to empty the receiver, then a `withdraw(1010, recovery)` with the **deployer's address appended** to the calldata. `multicall`'s delegatecall preserves `msg.sender == forwarder`, so the appended bytes make `_msgSender()` return the deployer — draining his whole deposit.

## The fix
Don't infer the sender from unauthenticated calldata; use a proper ERC-2771 `_msgSender()` that the forwarder authenticates. Require receiver opt-in for flash loans.
