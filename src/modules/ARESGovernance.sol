// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/interfaces/IGovernance.sol";
import "src/interfaces/ITimelock.sol";
import "src/modules/Treasury.sol";

abstract contract ARESGovernance is IGovernance, Treasury {
    // Main contract vault that handles everything. I.E This contract manages protocol governance, allowing authorized governors to Create treasury proposals, Approve proposals, Queue them in a timelock,Execute them after delay. 


    event GovernorsAdded(uint time);

    // initialize a variable to refrence the Timelock 
    ITimelock public timelock;

    mapping(address => bool) public governors;

    uint256 public proposalCount;
    uint256 public APPROVAL_THRESHOLD;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public approved;

    mapping(address => uint256) public rewards;

    modifier onlyGovernor() {
        require(governors[msg.sender], "Not governor");
        _;
    }
    

    //we pass doen the CA of this contract to the Treasury.
    constructor(address _timelock, address[] memory _governors) Treasury(address(this)) {
        timelock = ITimelock(_timelock);

        APPROVAL_THRESHOLD = (_governors.length * 60 + 99) / 100;

        for (uint i = 0; i < _governors.length; i++) {
            if (_governors[i] == address(0)) revert("Address 0 not allowed");
            governors[_governors[i]] = true;
        }

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

        require(p.proposer != address(0), "Invalid proposal"); // improvement
        require(!p.executed, "Already executed");

        timelock.execute(p.target, p.data);

        p.executed = true;
    }
}
