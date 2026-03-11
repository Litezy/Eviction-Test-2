// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/libraries/SigLib.sol";

contract GovSigAuth {
    // a nonce for one governor so we can prvent replay of the same signature
    mapping(address => uint256) public nonces;

    function _verifyApprovalSig(
        uint256 proposalId,
        address governor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        bytes32 domainSep  = SigLib.domainSeparator(address(this));
        bytes32 structHash = SigLib.hashApproval(proposalId, governor, nonces[governor]);
        address recovered  = SigLib.recover(domainSep, structHash, v, r, s);

        if (recovered != governor) return false;

        // increment nonce here to avoid sig being replayed
        nonces[governor]++;
        return true;
    }
}