# 06 — Selfie

**Class:** Flash-loan governance takeover · **Impact:** full drain

## Target
A pool with an `onlyGovernance` `emergencyExit()` drain, a governance contract that lets anyone with >50% of the voting token queue any action (2-day timelock), and a pool holding 1.5M of a 2M-supply voting token — lent out for free.

## The bug
Governance checks voting power **when an action is queued**, never **when it's executed**. Voting power can be borrowed.

## The exploit
Flash-loan 1.5M tokens (>50% supply), `delegate()` to self for the votes, `queueAction(pool, emergencyExit(recovery))`, repay the loan. Wait out the 2-day timelock, then `executeAction` — governance drains the pool to recovery. (Same class as the $182M Beanstalk hack.)

## The fix
Use **historical** voting snapshots (`getPastVotes` from before the proposal) so flash-loaned, same-block power can't authorize actions.
