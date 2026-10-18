// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title OZToken
/// @notice The same idea as StudyToken, built the production way: inheriting audited
///         OpenZeppelin code. Adds EIP-2612 `permit` (approve with an off-chain signature).
contract OZToken is ERC20, ERC20Permit, Ownable {
    constructor(uint256 initialSupply) ERC20("OZ Token", "OZT") ERC20Permit("OZ Token") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
