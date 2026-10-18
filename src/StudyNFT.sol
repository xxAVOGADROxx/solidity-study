// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title StudyNFT
/// @notice A paid-mint ERC-721 (EIP-721) collection with a capped supply.
contract StudyNFT is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant PRICE = 0.01 ether;
    uint256 public nextId;

    error SoldOut();
    error WrongPrice(uint256 sent);
    error WithdrawFailed();

    constructor() ERC721("Study NFT", "SNFT") Ownable(msg.sender) {}

    function mint() external payable returns (uint256 id) {
        // Checks
        if (msg.value != PRICE) revert WrongPrice(msg.value);
        id = nextId;
        if (id >= MAX_SUPPLY) revert SoldOut();
        // Effects: update state BEFORE the interaction. _safeMint calls
        // onERC721Received on the receiver if it is a contract, which can re-enter.
        nextId = id + 1;
        // Interaction
        _safeMint(msg.sender, id);
    }

    function withdraw() external onlyOwner {
        (bool ok,) = owner().call{value: address(this).balance}("");
        if (!ok) revert WithdrawFailed();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://example-cid/";
    }
}
