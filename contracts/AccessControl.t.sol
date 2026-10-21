// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AccessControlVulnerable} from "./AccessControlVulnerable.sol";
import {AccessControlSecured} from "./AccessControlSecured.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AccessControlTest is Test {
    AccessControlVulnerable vulnerable;
    AccessControlSecured secured;

    address attacker = address(0xBAD);

    function setUp() public {
        vulnerable = new AccessControlVulnerable();
        secured = new AccessControlSecured();
        vm.deal(address(this), 20 ether);
        vulnerable.deposit{value: 10 ether}();
        secured.deposit{value: 10 ether}();
    }

    // Vulnerable: a non-owner can drain it (the bug).
    function test_Vulnerable_AnyoneCanDrain() public {
        uint256 attackerBefore = attacker.balance;
        vm.prank(attacker);
        vulnerable.withdrawAll();
        assertEq(address(vulnerable).balance, 0);
        assertEq(attacker.balance, attackerBefore + 10 ether);
    }

    // Secured: a non-owner is blocked (the fix).
    function test_Secured_NonOwnerCannotDrain() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, attacker));
        secured.withdrawAll();
        assertEq(address(secured).balance, 10 ether);
    }

    // Secured: the owner can still withdraw.
    function test_Secured_OwnerCanWithdraw() public {
        uint256 ownerBefore = address(this).balance;
        secured.withdrawAll();
        assertEq(address(secured).balance, 0);
        assertEq(address(this).balance, ownerBefore + 10 ether);
    }

    receive() external payable {}
}