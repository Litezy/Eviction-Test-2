# ARES Governance Protocol

This document outlines the main features and workflow of the ARES governance system.

## How It Works

### Proposal Creation

- Any authorized governor can create a proposal
- You need to specify the target contract address and the calldata
- Each proposal gets a unique ID and is stored on-chain
- Only valid targets and non-empty calldata are accepted

### Approval Process

- Governors review proposals and cast their approvals
- Each governor's approval is recorded separately
- The system calculates approval thresholds based on total governors
- Governors earn 1 ether per approval they make
- Rewards can be claimed later using Merkle verification

### Queueing

- Once enough approvals are met, proposals go into the timelock
- The timelock sets an eta (earliest time of execution)
- This enforces a waiting period before anyone can run the proposal

### Execution

- After the waiting period passes, any governor can execute
- The target contract gets called with the provided calldata
- Once executed, the proposal status is marked to prevent replay

### Cancellation

- Governors can cancel proposals before execution,but in my design I actually toggled executed to be true in order to prevent reecxeution.
- This helps fix errors or address security concerns
- Canceled proposals cannot be queued or executed again

### Claiming Rewards

- Users in the Merkle tree can claim their rewards
- A Merkle proof is required to verify eligibility
- The system tracks who has claimed to prevent double-dipping
- Invalid proofs will cause the transaction to revert

## Flow Overview

```
Governor → createProposal → Proposal Created
Governor(s) → approveProposal → Approval Count Goes Up
Enough Approvals → queueProposal → Timelock Sets ETA
Governor → executeProposal → Target Contract Called
Governor(s) → cancelProposal (if needed)
User → claimReward → Merkle Proof Verified → Reward Claimed
```

## Quick Summary

This governance system lets multiple governors work together to manage treasury funds safely. Proposals need multiple approvals, a timelock wait period, and then can be executed. Rewards are distributed through a Merkle-based system to keep things efficient.

---

*For more details on the system design, check out ARCHITECTURE.md*

