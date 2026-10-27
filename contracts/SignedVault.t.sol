// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SignedVaultVulnerable} from "./SignedVaultVulnerable.sol";
import {SignedVaultSecured} from "./SignedVaultSecured.sol";

/// @dev The owner authorizes the attacker to withdraw exactly 1 ETH, once.
///      On the vulnerable vault the attacker replays that one signature to
///      drain everything. On the secured vault the replay reverts.
contract SignatureReplayTest is Test {
    uint256 ownerPk = 0xA11CE;
    address owner;
    address attacker = address(0xBEEF);

    function setUp() public {
        owner = vm.addr(ownerPk);
        vm.deal(address(this), 100 ether); // fund the deployer so vaults can hold ETH
    }

    function test_VulnerableVaultDrainedByReplay() public {
        SignedVaultVulnerable vault = new SignedVaultVulnerable{value: 5 ether}(owner);

        uint256 amount = 1 ether;
        bytes32 digest = keccak256(abi.encodePacked(attacker, amount));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        // Same signature, claimed 5 times.
        vm.startPrank(attacker);
        for (uint256 i = 0; i < 5; i++) {
            vault.claim(amount, v, r, s);
        }
        vm.stopPrank();

        // Authorized for 1 ETH once; walked away with all 5.
        assertEq(attacker.balance, 5 ether);
        assertEq(address(vault).balance, 0);
    }

    function test_SecuredVaultResistsReplay() public {
        SignedVaultSecured vault = new SignedVaultSecured{value: 5 ether}(owner);

        uint256 amount = 1 ether;
        bytes32 digest = vault.hashToSign(attacker, amount, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.startPrank(attacker);

        // First claim succeeds.
        vault.claim(amount, sig);
        assertEq(attacker.balance, 1 ether);

        // Replaying the SAME signature fails: the nonce advanced, so the digest
        // no longer matches and recovery yields a non-owner address.
        vm.expectRevert(bytes("invalid signature"));
        vault.claim(amount, sig);

        vm.stopPrank();

        // Attacker got only the 1 ETH they were actually authorized for.
        assertEq(attacker.balance, 1 ether);
        assertEq(address(vault).balance, 4 ether);
    }
}
