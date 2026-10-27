# 09 — Puppet V2

**Class:** Spot-price oracle manipulation (Uniswap V2) · **Impact:** full drain

## Target
Puppet's successor: collateral is **WETH** at **3×** value, priced from **Uniswap V2 reserves**. Pair: 100 DVT / 10 WETH. You hold 10,000 DVT and 20 ETH; the pool holds 1,000,000 DVT.

## The bug
Same root cause as Puppet — the pool trusts an instantaneous Uniswap **V2** spot price from a shallow pool.

## The exploit
No one-tx constraint, so act directly: (1) swap all 10,000 DVT → ~9.9 WETH, cratering the price; (2) wrap 20 ETH → 20 WETH; (3) the pool now demands ~29.5 WETH to borrow all 1,000,000 DVT, covered by your ~29.9 WETH — borrow it all; (4) send to recovery.

## The fix
Use a TWAP or external oracle with deviation and liquidity guards instead of a raw spot quote.
