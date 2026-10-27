# 04 — Side Entrance

**Class:** Flash-loan accounting confusion · **Impact:** full drain

## Target
A pool with `deposit()` / `withdraw()` and a free ETH flash loan.

## The bug
`flashLoan` only checks that the **raw ETH balance** is restored:
```solidity
uint256 balanceBefore = address(this).balance;
IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
if (address(this).balance < balanceBefore) revert RepayFailed();
```
It never distinguishes "repaid loan" from "new deposit."

## The exploit
In the flash-loan callback, call `deposit()` with the borrowed ETH. The pool's raw balance is restored (check passes) **and** your `balances[]` credit is created. Afterwards, `withdraw()` your credit — draining the pool. Forward to recovery.

## The fix
Track repayment through internal accounting, not `address(this).balance`. A repayment must not be creditable as a deposit.
