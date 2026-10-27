# Damn Vulnerable DeFi — Write-ups

Self-directed solutions to [Damn Vulnerable DeFi v4](https://damnvulnerabledefi.xyz), the canonical smart-contract security wargame. Each write-up covers the **vulnerability class**, the **exploit**, and the **fix**, with a working Foundry PoC behind it.

> Training material — these are public wargame challenges, documented to demonstrate methodology across DeFi bug classes, not novel discoveries.

| # | Challenge | Bug class |
|---|-----------|-----------|
| 1 | [Unstoppable](01-unstoppable.md) | ERC4626 accounting invariant broken by a donation |
| 2 | [Naive Receiver](02-naive-receiver.md) | Flash-loan fee griefing + meta-tx sender spoofing |
| 3 | [Truster](03-truster.md) | Arbitrary external call → self-approval |
| 4 | [Side Entrance](04-side-entrance.md) | Flash-loan repayment via deposit double-credit |
| 5 | [The Rewarder](05-the-rewarder.md) | Batch double-claim (delayed bitmap update) |
| 6 | [Selfie](06-selfie.md) | Flash-loan governance takeover |
| 7 | [Compromised](07-compromised.md) | Leaked oracle keys → median price control |
| 8 | [Puppet](08-puppet.md) | Uniswap V1 spot-price manipulation |
| 9 | [Puppet V2](09-puppet-v2.md) | Uniswap V2 spot-price manipulation |

**Recurring theme:** most of these reduce to *trusting a value that an attacker controls* — a raw balance, appended calldata, a spot price, a vote snapshot, or a single-use guard that isn't actually single-use.
