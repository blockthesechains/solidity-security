# Solidity Security Patterns

Hands-on smart contract security: common vulnerabilities shown next to their hardened fixes, each with a test that proves the fix holds. Built with Solidity, OpenZeppelin, and Hardhat 3.

## 1. Reentrancy

**The bug** (`ReentrancyBankVulnerable.sol`): sends ETH *before* updating the balance, so a malicious contract can re-enter `withdraw()` and drain funds. The flaw behind The DAO hack (2016).

**The fix** (`ReentrancyBankSecured.sol`): two layered defenses.
1. **Checks-Effects-Interactions** — state updates *before* the external call. Primary fix.
2. **ReentrancyGuard (`nonReentrant`)** — blocks nested calls as a backstop.

**The proof** (`ReentrancyBankSecured.t.sol`): an attacker tries to re-enter `withdraw()` to steal a victim's 10 ETH. The reentry is blocked, the attacker gets only their own deposit back, and the victim's funds stay safe.

## 2. Access Control

**The bug** (`AccessControlVulnerable.sol`): a `withdrawAll()` with no owner check — *any* address can call it and drain the contract. Missing access control is one of the most common real-world vulnerabilities.

**The fix** (`AccessControlSecured.sol`): restricts the function with OpenZeppelin's `Ownable` + `onlyOwner`.

**The proof** (`AccessControl.t.sol`): on the vulnerable contract a random attacker drains the full balance; on the secured one that same call reverts and the funds stay safe, while the owner can still withdraw.

> The vulnerable contracts are for education only and are labeled "do not deploy."

## Running locally

    npm install
    npx hardhat compile
    npx hardhat test

## Tech

Solidity 0.8.x · OpenZeppelin Contracts · Hardhat 3 · forge-std