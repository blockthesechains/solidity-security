# 01 — Unstoppable

**Class:** Broken accounting invariant (ERC4626) · **Impact:** permanent DoS

## Target
An ERC4626 vault offering free flash loans. A monitor pauses the vault if a flash loan ever fails.

## The bug
`flashLoan()` enforces an invariant before lending:
```solidity
uint256 balanceBefore = totalAssets();                       // = asset.balanceOf(vault)
if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();
```
`totalAssets()` is the raw token balance. The invariant assumes tokens only ever enter via `deposit()` (which mints matching shares), keeping balance and share accounting in lockstep.

## The exploit
Transfer **1 wei** of the asset directly to the vault. `balanceOf` rises, `totalSupply` doesn't, the invariant breaks, and every future flash loan reverts — the monitor then pauses the vault.

## The fix
Never derive accounting from `balanceOf`. Track deposited assets in internal state so unsolicited (donated) transfers can't break the invariant.
