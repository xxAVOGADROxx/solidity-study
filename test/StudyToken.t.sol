// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StudyToken} from "../src/StudyToken.sol";

contract StudyTokenTest is Test {
    StudyToken token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant SUPPLY = 1_000e18;

    // Runs before every test, on a fresh EVM state.
    function setUp() public {
        token = new StudyToken("Study Token", "STD", SUPPLY);
    }

    // --- Unit tests -------------------------------------------------------------------------

    function test_InitialSupplyGoesToDeployer() public view {
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(address(this)), SUPPLY);
    }

    function test_Transfer() public {
        // vm.expectEmit checks the next event matches the one we emit here.
        vm.expectEmit(address(token));
        emit StudyToken.Transfer(address(this), alice, 100e18);
        token.transfer(alice, 100e18);

        assertEq(token.balanceOf(alice), 100e18);
        assertEq(token.balanceOf(address(this)), SUPPLY - 100e18);
    }

    function test_RevertWhen_InsufficientBalance() public {
        vm.prank(alice); // the next call comes from alice, who has 0 tokens
        vm.expectRevert(abi.encodeWithSelector(StudyToken.InsufficientBalance.selector, alice, 0, 1));
        token.transfer(bob, 1);
    }

    function test_TransferFromSpendsAllowance() public {
        token.approve(alice, 50e18);

        vm.prank(alice);
        token.transferFrom(address(this), bob, 30e18);

        assertEq(token.balanceOf(bob), 30e18);
        assertEq(token.allowance(address(this), alice), 20e18);
    }

    function test_InfiniteAllowanceIsNotSpent() public {
        token.approve(alice, type(uint256).max);

        vm.prank(alice);
        token.transferFrom(address(this), bob, 30e18);

        assertEq(token.allowance(address(this), alice), type(uint256).max);
    }

    function test_RevertWhen_NonOwnerMints() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(StudyToken.NotOwner.selector, alice));
        token.mint(alice, 1);
    }

    // --- Fuzz tests: Foundry picks random inputs (like QuickCheck) ---------------------------

    function testFuzz_TransferMovesExactAmount(address to, uint256 amount) public {
        vm.assume(to != address(0) && to != address(this));
        amount = bound(amount, 0, SUPPLY); // shrink the input into a valid range

        token.transfer(to, amount);

        assertEq(token.balanceOf(to), amount);
        assertEq(token.balanceOf(address(this)), SUPPLY - amount);
        assertEq(token.totalSupply(), SUPPLY);
    }
}

/// @notice The invariant fuzzer calls these functions in random order with random inputs.
///         A handler keeps the calls meaningful (valid senders, bounded amounts).
contract TokenHandler is Test {
    StudyToken token;
    address[] actors;

    constructor(StudyToken token_) {
        token = token_;
        actors.push(makeAddr("actor0"));
        actors.push(makeAddr("actor1"));
        actors.push(makeAddr("actor2"));
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(from));
        vm.prank(from);
        token.transfer(to, amount);
    }

    function mint(uint256 toSeed, uint256 amount) external {
        amount = bound(amount, 0, 1e30);
        vm.prank(token.owner());
        token.mint(actors[toSeed % actors.length], amount);
    }

    function sumOfBalances() external view returns (uint256 sum) {
        for (uint256 i = 0; i < actors.length; i++) {
            sum += token.balanceOf(actors[i]);
        }
    }
}

contract StudyTokenInvariantTest is Test {
    StudyToken token;
    TokenHandler handler;

    function setUp() public {
        token = new StudyToken("Study Token", "STD", 0);
        handler = new TokenHandler(token);
        targetContract(address(handler)); // only fuzz through the handler
    }

    /// Must hold after ANY sequence of transfers and mints.
    function invariant_SumOfBalancesEqualsTotalSupply() public view {
        assertEq(handler.sumOfBalances(), token.totalSupply());
    }
}
