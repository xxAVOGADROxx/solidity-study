// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title StudyToken
/// @notice A from-scratch ERC-20 (EIP-20) to learn how the standard works.
/// @dev For learning only. In production, inherit from OpenZeppelin (see OZToken.sol).
contract StudyToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    // Public mappings generate the `balanceOf(address)` and `allowance(address,address)` getters
    // that the standard requires.
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // `immutable` is written once in the constructor and stored in the bytecode, not in storage:
    // reading it costs almost no gas.
    address public immutable owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Custom errors are cheaper than `require(cond, "string")` and carry typed data.
    error InsufficientBalance(address from, uint256 balance, uint256 needed);
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error InvalidReceiver(address receiver);
    error NotOwner(address caller);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply) {
        name = name_;
        symbol = symbol_;
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 current = allowance[from][msg.sender];
        // Convention: an allowance of type(uint256).max is "infinite" and is never decreased.
        if (current != type(uint256).max) {
            if (current < value) revert InsufficientAllowance(msg.sender, current, value);
            unchecked {
                allowance[from][msg.sender] = current - value;
            }
        }
        _transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _mint(to, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (to == address(0)) revert InvalidReceiver(to);
        uint256 fromBalance = balanceOf[from];
        if (fromBalance < value) revert InsufficientBalance(from, fromBalance, value);
        // Safe to skip overflow checks: we just checked fromBalance >= value, and no balance
        // can exceed totalSupply, whose own addition in _mint is checked.
        unchecked {
            balanceOf[from] = fromBalance - value;
            balanceOf[to] += value;
        }
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        if (to == address(0)) revert InvalidReceiver(to);
        totalSupply += value; // checked: reverts on overflow
        unchecked {
            balanceOf[to] += value;
        }
        emit Transfer(address(0), to, value);
    }
}
