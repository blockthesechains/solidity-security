// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ReentrancyBankSecured} from "./ReentrancyBankSecured.sol";

/// @dev Tries to re-enter withdraw() during the refund. Against the secured
///      bank, the nonReentrant guard blocks it, so it can never drain more
///      than it deposited.
contract ReentrancyProbe {
    ReentrancyBankSecured public bank;
    uint256 public attackAmount;
    uint256 public reentryAttempts;

    constructor(ReentrancyBankSecured _bank) {
        bank = _bank;
    }

    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    function attack(uint256 amount) external {
        attackAmount = amount;
        bank.withdraw(amount);
    }

    receive() external payable {
        reentryAttempts++;
        // Try to re-enter. The guard forces this to revert.
        try bank.withdraw(attackAmount) {
            // Never reached on the secured bank.
        } catch {
            // Expected: reentrancy blocked.
        }
    }
}

contract ReentrancyBankSecuredTest is Test {
    ReentrancyBankSecured bank;
    ReentrancyProbe probe;

    address victim = address(0xBEEF);

    function setUp() public {
        bank = new ReentrancyBankSecured();
        probe = new ReentrancyProbe(bank);

        // An innocent user deposits 10 ETH — what an attacker would try to steal.
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        bank.deposit{value: 10 ether}();
    }

    function test_SecuredBankResistsReentrancy() public {
        // Attacker deposits 1 ETH of their own.
        vm.deal(address(this), 1 ether);
        probe.deposit{value: 1 ether}();
        assertEq(address(bank).balance, 11 ether);

        // Attacker runs the reentrancy attack.
        probe.attack(1 ether);

        // A reentry WAS attempted...
        assertGt(probe.reentryAttempts(), 0);
        // ...but the attacker only got its own 1 ETH back — no drain.
        assertLe(address(probe).balance, 1 ether);
        // The victim's 10 ETH is still safe.
        assertEq(address(bank).balance, 10 ether);
        assertEq(bank.balances(victim), 10 ether);
    }
}