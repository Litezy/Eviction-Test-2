// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/GovMerkle.sol";

contract GovMerkleAuth {

    bytes32 public root;

    mapping(address => bool) public claimed;

    constructor(bytes32 _root) {
        root = _root;
    }

    function verify(
        address user,
        bytes32[] calldata proof
    ) public view returns (bool) {

        return GovMerkle.verify(
            proof,
            root,
            keccak256(abi.encode(user))
        );
    }

    function markClaimed(address user) internal {
        require(user != address(0), "Address 0 not allowed");
        claimed[user] = true;
    }

    function checkIfClaimed(address user) public view returns (bool) {
        return claimed[user];
    }

    
}