// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/interfaces/IGovernance.sol";
import "src/interfaces/ITimelock.sol";
import "src/modules/GovGuard.sol";
import "src/modules/GovMerkleAuth.sol";
import "src/modules/Treasury.sol";

contract ARESGovernance is IGovernance, Treasury, GovGuard, GovMerkleAuth {
    // Main contract vault that handles everything. I.E This contract manages protocol governance, allowing authorized governors to Create treasury proposals, Approve proposals, Queue them in a timelock,Execute them after delay.

    event GovernorsAdded(uint time);

    // initialize a variable to refrence the Timelock
    ITimelock public timelock;

    uint256 public proposalCount;
    uint256 public APPROVAL_THRESHOLD;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public approved;

    mapping(address => uint256) public rewards;

    //we pass doen the CA of this contract to the Treasury, pass root to GovMerkle,set timelock and set governors.
    constructor(
        address _timelock,
        address[] memory _governors,
        bytes32 _root
    ) Treasury(address(this)) GovMerkleAuth(_root) {
        timelock = ITimelock(_timelock);

        APPROVAL_THRESHOLD = (_governors.length * 60 + 99) / 100;

        _setGovernors(_governors);

        emit GovernorsAdded(block.timestamp);
    }

    //In my design i am restricting creation of proposals to be only a governor, so from my research  it takes in a target (the CA that will be called during execution) and then calldata (the CA that will be called during execution)
    function createProposal(
        address target,
        bytes calldata data
    ) external onlyGovernor returns (uint256) {
        require(target != address(0), "Invalid target");
        require(data.length > 0, "Empty calldata");

        proposalCount++;

        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            target: target,
            data: data,
            approvals: 0,
            executed: false,
            eta: 0
        });

        return proposalCount;
    }

    //governor approves, just like in a multisig setting
    function approve(uint256 proposalId) external onlyGovernor {
        Proposal storage p = proposals[proposalId];

        require(p.proposer != address(0), "Invalid proposal");
        require(!approved[proposalId][msg.sender], "Already approved");

        approved[proposalId][msg.sender] = true;

        p.approvals++;

        rewards[msg.sender] += 1 ether;
    }

    function queue(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];

        require(p.proposer != address(0), "Invalid proposal");
        require(p.approvals >= APPROVAL_THRESHOLD, "Not enough approvals");

        uint256 eta = timelock.queue(p.target, p.data);

        p.eta = eta;
    }

    function execute(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];

        require(p.proposer != address(0), "Invalid proposal");
        require(!p.executed, "Already executed");

        timelock.execute(p.target, p.data);

        p.executed = true;
    }

    // rewards claim
    function claimReward(bytes32[] calldata proof) external {
        require(!checkIfClaimed(msg.sender), "already claimed");
        require(verify(msg.sender, proof), "invalid proof");
        markClaimed(msg.sender);
        rewards[msg.sender] += 1 ether;
    }

    function withdrawReward() external {
        uint amount = rewards[msg.sender];
        require(amount > 0, "no reward");
        rewards[msg.sender] = 0;
        //prevent reentrancy
        transfer(msg.sender, amount);
    }

    // getter fn for proposal
    function getProposal(
        uint256 proposalId
    )
        external
        view
        returns (
            address proposer,
            address target,
            bytes memory data,
            uint256 approvals,
            bool executed,
            uint256 eta
        )
    {
        Proposal storage p = proposals[proposalId];
        return (p.proposer, p.target, p.data, p.approvals, p.executed, p.eta);
    }
}
