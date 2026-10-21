\# Audit Findings — RewardPool



An audit of `RewardPoolVulnerable.sol`, a staking contract that pays stakers a share of a reward pool. Two related vulnerabilities allow an attacker to steal the entire reward pool.



\## Summary



| # | Finding | Severity |

|---|---------|----------|

| 1 | Rewards can be claimed repeatedly (no claim accounting) | Critical |

| 2 | Flash-loan stake captures the entire reward pool | Critical |



Both stem from one root cause: \*\*rewards are paid on a staker's \*instantaneous\* share at claim time, and nothing records what has already been claimed.\*\*



\---



\## Finding 1 — Unbounded repeated claims



\*\*Severity:\*\* Critical



\*\*Root cause:\*\* `claimReward()` pays `rewardBalance \* staked\[user] / totalStaked` and decrements `rewardBalance`, but never reduces or marks `staked\[user]`. The stake is a \*reusable\* ticket — every call returns a positive share of whatever balance remains.



\*\*Preconditions:\*\* Non-zero `rewardBalance`; attacker holds any stake.



\*\*Attack:\*\*

1\. Attacker stakes any amount.

2\. Attacker calls `claimReward()` repeatedly. Each call pays their proportional share of the \*remaining\* balance, with no limit on calls.



\*\*Impact:\*\* The repeated proportional claims form a geometric series that sums to the \*entire\* `rewardBalance`, so a staker of any size can drain the whole pool. Future `addRewards()` top-ups can be drained the same way, making the theft indefinite.



\*\*Note on reentrancy:\*\* If the staking token hands control to the recipient on transfer (e.g. ERC-777), the attacker can also re-enter `claimReward()` to sweep the balance in a single transaction. Reentrancy is only a faster delivery of the same root flaw; plain ERC-20 does not enable it.



\---



\## Finding 2 — Flash-loan stake drains the pool atomically



\*\*Severity:\*\* Critical



\*\*Root cause:\*\* Because a claim is based on \*instantaneous\* share of `totalStaked`, an attacker can briefly inflate their stake with borrowed capital, claim, and withdraw — all in one transaction.



\*\*Preconditions:\*\* Non-zero `rewardBalance` with honest stakers present. No attacker capital required.



\*\*Attack (single transaction):\*\*

1\. Flash-loan a large amount `L` of `token` (`L` >> `totalStaked`).

2\. `stake(L)` — `staked\[attacker]` now dominates `totalStaked`.

3\. `claimReward()` — `share ≈ rewardBalance` (\~100%).

4\. `unstake(L)` — recover the principal.

5\. Repay the flash loan.



\*\*Impact:\*\* The attacker takes \~the entire reward pool with zero capital and zero risk (atomic). Honest stakers' rewards are diluted to near-zero.



\---



\## Recommendation



Replace instantaneous-share accounting with a \*\*reward-per-token accumulator\*\* (the Synthetix `StakingRewards` pattern), implemented in `RewardPoolSecured.sol`:



\- Track a global `rewardPerTokenStored` that grows only when rewards are added.

\- Snapshot each user's `userRewardPerTokenPaid` (reward debt) on every stake/unstake/claim.

\- A user earns `staked \* (rewardPerTokenStored - userRewardPerTokenPaid)`.



This keys rewards to \*\*stake × the time rewards existed\*\*, not instantaneous share, defeating both findings:

\- Claiming twice yields zero (the debt is settled on claim).

\- A flash-loaned stake earns zero (it accrued over no reward period).



See `RewardPool.t.sol` for tests proving a flash-loan stake and a double-claim both earn nothing, while an honest staker receives their full reward.

