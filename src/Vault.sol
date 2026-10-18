// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}

/// @title VulnerableVault
/// @notice DO NOT USE. Sends ETH before updating the balance, so a malicious contract can
///         re-enter `withdraw` from its `receive` and drain every depositor.
///         See test/Vault.t.sol for the attack.
contract VulnerableVault is IVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        // BUG: interaction before effect. The receiver runs code here and can call
        // withdraw() again while balances[msg.sender] is still `amount`.
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
        balances[msg.sender] = 0;
    }
}

/// @title SafeVault
/// @notice The fix, applied twice: Checks-Effects-Interactions ordering, plus OpenZeppelin's
///         ReentrancyGuard as defense in depth.
contract SafeVault is IVault, ReentrancyGuard {
    mapping(address => uint256) public balances;

    error NothingToWithdraw();
    error SendFailed();

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender]; // Checks
        if (amount == 0) revert NothingToWithdraw();
        balances[msg.sender] = 0; // Effects
        (bool ok,) = msg.sender.call{value: amount}(""); // Interactions
        if (!ok) revert SendFailed();
    }
}
