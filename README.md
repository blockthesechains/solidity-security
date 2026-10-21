# Solidity Security Patterns

Hands-on smart contract security: a common vulnerability shown next to its hardened fix, with a test that proves the fix holds under attack. Built with Solidity, OpenZeppelin, and Hardhat 3.

## Reentrancy

**The bug** (`ReentrancyBankVulnerable.sol`): the classic mistake, it sends ETH *before* updating the user's balance. A malicious contract can re-enter `withdraw()` during the transfer and drain funds. This is the flaw behind The DAO hack (2016).

**The fix** (`ReentrancyBankSecured.sol`): two layered defenses.
1. **Checks-Effects-Interactions** — balances update *before* the external call, so a reentrant call fails the balance check. This is the primary fix.
2. **ReentrancyGuard (`nonReentrant`)** — OpenZeppelin's guard blocks any nested call as a backstop (defense in depth).

**The proof** (`ReentrancyBankSecured.t.sol`): an attacker deposits 1 ETH, then tries to re-enter `withdraw()` to steal a victim's 10 ETH. The test confirms the reentry is attempted but blocked, the attacker recovers only their own 1 ETH, and the victim's funds stay untouched.

> The vulnerable contract is for education only and is labeled "do not deploy."

## Running locally

    npm install
    npx hardhat compile
    npx hardhat test

## Tech

Solidity 0.8.x · OpenZeppelin Contracts · Hardhat 3 · forge-std