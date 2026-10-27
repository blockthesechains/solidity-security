# 05 — The Rewarder

**Class:** Batch double-claim (delayed state update) · **Impact:** full drain

## Target
A Merkle + bitmap reward distributor. Across separate transactions the "already claimed" guard works correctly.

## The bug
In `claimRewards`, payment happens **every loop iteration**, but the claimed-bit is only written to storage on a **token change** or the **last claim** — once per token per call. Within a single call the storage bitmap is never re-read per iteration.

## The exploit
Find your own legitimate claim (amount + Merkle proof), then submit it `remaining / amount` times in a **single** `claimRewards` call. Every repeat is paid; the bit is set once. Order all claims of one token together so the flush is clean. Drains both the DVT and WETH distributions; send to recovery.

## The fix
Mark each claim consumed **before** paying it (checks-effects-interactions), and reject duplicate claim indices within a batch.
