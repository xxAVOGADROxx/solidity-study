// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StudyNFT} from "../src/StudyNFT.sol";

contract StudyNFTTest is Test {
    StudyNFT nft;
    address alice = makeAddr("alice");

    function setUp() public {
        nft = new StudyNFT();
        vm.deal(alice, 1 ether); // give alice ETH
    }

    // The test contract is the owner, so it must accept ETH from withdraw().
    receive() external payable {}

    function test_MintAssignsOwnershipAndUri() public {
        uint256 price = nft.PRICE();
        vm.prank(alice);
        uint256 id = nft.mint{value: price}();

        assertEq(nft.ownerOf(id), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.tokenURI(id), "ipfs://example-cid/0");
    }

    function test_RevertWhen_WrongPrice() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(StudyNFT.WrongPrice.selector, 1 wei));
        nft.mint{value: 1 wei}();
    }

    function test_OwnerWithdrawsProceeds() public {
        uint256 price = nft.PRICE();
        vm.prank(alice);
        nft.mint{value: price}();

        uint256 before = address(this).balance;
        nft.withdraw();
        assertEq(address(this).balance, before + price);
        assertEq(address(nft).balance, 0);
    }
}
