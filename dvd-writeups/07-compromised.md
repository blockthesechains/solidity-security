# 07 — Compromised

**Class:** Oracle key compromise + median manipulation · **Impact:** full drain

## Target
An NFT exchange that prices DVNFT from a `TrustfulOracle` — the **median** of 3 trusted reporters. An HTTP response leaks data.

## The bug
The leaked hex decodes (hex → ASCII → base64 → key) into **two private keys** belonging to two of the three oracle reporters. Controlling 2 of 3 sources means controlling the median price.

## The exploit
As the two compromised sources: crash the price to ~0 → `buyOne()` an NFT for nothing → pump the price to the exchange's balance → `sellOne()` to drain its 999 ETH → send to recovery → **reset the price** to its original value so the oracle looks untouched.

## The fix
Never expose signing keys; rotate on compromise; require more sources and plausibility bounds so a minority (or a thin majority) can't swing the median.
