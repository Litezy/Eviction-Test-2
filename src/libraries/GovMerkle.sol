// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

library GovMerkle {

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns(bool){
        return MerkleProof.verify(proof,root,leaf);
    }

}