# 08 — Puppet

**Class:** Spot-price oracle manipulation (Uniswap V1) · **Impact:** full drain

## Target
A lending pool requiring 2× a token's value in ETH as collateral, priced from a **Uniswap V1 pair's spot reserves** (`ETH / token`). The pair is shallow: 10 DVT / 10 ETH. You hold 1,000 DVT; the pool holds 100,000 DVT.

## The bug
The collateral price is the instantaneous reserve ratio of a shallow pool — trivially moved by a large trade. No TWAP, no depth check.

## The exploit
Dump all 1,000 DVT into the 10-DVT pair, collapsing the DVT price. Required collateral to borrow 100,000 DVT falls to ~20 ETH, easily covered by your 25 ETH plus the ETH from the dump. Borrow the pool dry to recovery — one tx, using an EIP-2612 `permit` so the token moves without a separate approval.

## The fix
Price from a manipulation-resistant oracle (TWAP / Chainlink) with liquidity and deviation safeguards.
