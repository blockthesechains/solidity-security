# Solidity Security Patterns

Hands-on smart contract security: common vulnerabilities shown next to their hardened fixes, each with a test that proves the fix holds. Built with Solidity, OpenZeppelin, and Hardhat 3.

## 1. Reentrancy

**The bug** (`ReentrancyBankVulnerable.sol`): sends ETH *before* updating the balance, so a malicious contract can re-enter `withdraw()` and drain funds. The flaw behind The DAO hack (2016).

**The fix** (`ReentrancyBankSecured.sol`): two layered defenses.
1. **Checks-Effects-Interactions** — state updates *before* the external call. Primary fix.
2. **ReentrancyGuard (`nonReentrant`)** — blocks nested calls as a backstop.

**The proof** (`ReentrancyBankSecured.t.sol`): an attacker tries to re-enter `withdraw()` to steal a victim's 10 ETH. The reentry is blocked, the attacker gets only their own deposit back, and the victim's funds stay safe. Full write-up in [`findings/reentrancy-bank.md`](findings/reentrancy-bank.md).

## 2. Access Control

**The bug** (`AccessControlVulnerable.sol`): a `withdrawAll()` with no owner check — *any* address can call it and drain the contract. Missing access control is one of the most common real-world vulnerabilities.

**The fix** (`AccessControlSecured.sol`): restricts the function with OpenZeppelin's `Ownable` + `onlyOwner`.

**The proof** (`AccessControl.t.sol`): on the vulnerable contract a random attacker drains the full balance; on the secured one that same call reverts and the funds stay safe, while the owner can still withdraw.

## 3. Reward Accounting & Flash-Loan Manipulation

**The bug** (`RewardPoolVulnerable.sol`): a staking pool pays rewards based on a staker's *instantaneous* share at claim time, with no record of what's been claimed. This enables unbounded repeated claims and — devastatingly — a flash-loan stake that captures the entire reward pool in a single transaction with zero capital. Full write-up in [`findings/reward-pool.md`](findings/reward-pool.md).

**The fix** (`RewardPoolSecured.sol`): a reward-per-token accumulator (Synthetix `StakingRewards` pattern) that keys rewards to stake × the time rewards existed, not instantaneous share. A flash-loaned stake earns nothing, and claims can't be repeated.

**The proof** (`RewardPool.t.sol`): a flash-loan-style stake and a double-claim both earn zero, while an honest staker who was staked when rewards were added receives their full share.

## 4. Signature Replay

**The bug** (`SignedVaultVulnerable.sol`): a vault releases ETH on an owner's signature but records no nonce and no domain separation — so one valid signature can be replayed to withdraw again and again until the vault is empty. Behind many airdrop and meta-transaction exploits. Full write-up in [`findings/signature-replay.md`](findings/signature-replay.md).

**The fix** (`SignedVaultSecured.sol`): three layers — a per-user **nonce** (each signature is single-use), **EIP-712** domain separation (binds signatures to this contract + chain), and OpenZeppelin **`ECDSA.recover`** (rejects malformed/malleable signatures).

**The proof** (`SignedVault.t.sol`): the owner authorizes 1 ETH once; on the vulnerable vault the attacker replays that signature to drain 5 ETH, and on the secured vault the replay reverts — the attacker keeps only the 1 ETH they were granted.

> The vulnerable contracts are for education only and are labeled "do not deploy."

## Practice Audits

Self-directed audit passes on public training codebases, written up in the style of a competitive-audit report.

- [`findings/puppyraffle-practice.md`](findings/puppyraffle-practice.md) — a full pass on Cyfrin's **PuppyRaffle** teaching contract, finding four bugs across four classes: reentrancy, weak randomness, unsafe cast/overflow, and an O(n²) denial-of-service. *(Training material — bugs are documented course content, not novel discoveries.)*

## Damn Vulnerable DeFi

Solved challenges from the [Damn Vulnerable DeFi v4](https://damnvulnerabledefi.xyz) wargame, each with a working Foundry PoC and a write-up of the bug class, exploit, and fix. See [`dvd-writeups/`](dvd-writeups/) — covers accounting-invariant breaks, flash-loan fee griefing, meta-transaction sender spoofing, arbitrary-call self-approval, flash-loan deposit double-credits, batch double-claims, flash-loan governance takeover, oracle key compromise, and Uniswap V1/V2 spot-price manipulation.

## Running locally

    npm install
    npx hardhat compile
    npx hardhat test

## Tech

Solidity 0.8.x · OpenZeppelin Contracts · Hardhat 3 · forge-std