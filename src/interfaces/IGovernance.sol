// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGovernance {

    struct Proposal {
        address proposer;
        address target;
        // addres to 
        bytes data;
        uint256 approvals;
        bool executed;
        uint256 eta;
    }

    function createProposal(address target, bytes calldata data) external returns(uint256);

    function approve(uint256 proposalId) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;
}