# ARES Protocol Implementation TODO

## Phase 1: Core Infrastructure
- [ ] Create interfaces in src/interfaces/
  - [ ] IARESProtocol.sol
  - [ ] ITreasuryProposal.sol
  - [ ] ITreasuryExecution.sol
  - [ ] IDistribution.sol

## Phase 2: Module Implementation
- [ ] Implement ProposeTreasury.sol (Module 1 - Transaction Proposal System)
- [ ] Implement Execution.sol (Module 3 - Time-Delayed Execution Engine)
- [ ] Implement Distribution.sol (Module 4 - Contributor Reward Distribution)

## Phase 3: Core Contracts
- [ ] Create src/core/ARESTreasury.sol - Main treasury contract
- [ ] Implement governance attack mitigation (Module 5)

## Phase 4: Documentation
- [ ] Complete ARCHITECTURE.md
- [ ] Complete SECURITY.md
- [ ] Create README.md

## Phase 5: Testing
- [ ] Create Foundry test suite
- [ ] Functional tests (proposal lifecycle, signature verification, timelock, reward claiming)
- [ ] Exploit tests (reentrancy, double claim, invalid signature, premature execution, proposal replay)
- [ ] Minimum 8 negative test cases

## Phase 6: Final Polish
- [ ] Ensure 5+ Solidty files in src/
- [ ] Verify proper module separation
- [ ] Ensure no boilerplate from existing protocols

