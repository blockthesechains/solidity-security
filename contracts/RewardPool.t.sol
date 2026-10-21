// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RewardPoolSecured} from "./RewardPoolSecured.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MOCK") { _mint(msg.sender, 10_000_000 ether); }
}

contract RewardPoolSecuredTest is Test {
    MockToken token;
    RewardPoolSecured pool;

    address alice = address(0xA11CE);     // honest staker
    address attacker = address(0xBAD);

    function setUp() public {
        token = new MockToken();
        pool = new RewardPoolSecured(token);

        token.transfer(alice, 1_000 ether);
        token.transfer(attacker, 1_000_000 ether);

        vm.startPrank(alice);
        token.approve(address(pool), type(uint256).max);
        pool.stake(100 ether);
        vm.stopPrank();

        token.approve(address(pool), type(uint256).max);       // test contract funds rewards
        vm.prank(attacker);
        token.approve(address(pool), type(uint256).max);

        pool.addRewards(1_000 ether);                          // added while only Alice is staked
    }

    // Flash-loan-style stake captures nothing.
    function test_FlashLoanStakeEarnsNothing() public {
        vm.startPrank(attacker);
        pool.stake(1_000_000 ether);
        vm.expectRevert(RewardPoolSecured.NoRewards.selector);
        pool.claimReward();
        vm.stopPrank();
    }

    // Honest staker earns the full reward.
    function test_HonestStakerEarnsReward() public {
        assertEq(pool.earned(alice), 1_000 ether);
        vm.prank(alice);
        pool.claimReward();
        assertEq(token.balanceOf(alice), 900 ether + 1_000 ether);
    }

    // Can't claim the same rewards twice.
    function test_CannotClaimTwice() public {
        vm.startPrank(alice);
        pool.claimReward();
        vm.expectRevert(RewardPoolSecured.NoRewards.selector);
        pool.claimReward();
        vm.stopPrank();
    }
}