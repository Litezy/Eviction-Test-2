// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library SigLib {

    // we need to add EIP-712 signing to our approve() flow so governors can sign off-chain and someone submits the signatures on-chain
    bytes32 constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 constant APPROVAL_TYPEHASH =
        keccak256("Approval(uint256 proposalId,address governor,uint256 nonce)");

    function domainSeparator(address verifyingContract) internal view returns (bytes32) {
        return keccak256(abi.encode(
            DOMAIN_TYPEHASH,
            keccak256("ARESGovernance"),
            keccak256("1"),
            block.chainid,
            verifyingContract
        ));
    }

    function hashApproval(uint256 proposalId, address governor, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(APPROVAL_TYPEHASH, proposalId, governor, nonce));
    }

    function recover(bytes32 domainSep, bytes32 structHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        //we check for maleability here
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid sig: high s"
        );
        require(v == 27 || v == 28, "invalid signature: bad v");

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));
        return ecrecover(digest, v, r, s);
    }
}