# SECURITY.md — ARES Governance Protocol

## Overview

This document walks through the major security considerations I had in mind when building the ARES governance system. I will explain what could go wrong, how I handled each risk, and what still needs attention before this goes to production.

---

## Major Attack Surfaces

### 1. Unauthorized Proposal Creation and Approval

The most obvious entry point is the proposal system itself. If anyone could create or approve proposals, an attacker could push a malicious treasury drain through governance without any resistance.

I handled this with the `onlyGovernor` modifier that lives in `GovGuard`. Every sensitive function — `createProposal`, `approve`, `cancelProposal` — checks that the caller is a recognized governor before doing anything. Non-governors hit an immediate revert with no state change.

### 2. Premature Execution

Without a delay, an attacker who somehow gains governor access could create, approve, and execute a proposal in the same block. This is one of the most common governance exploits in the wild.

I addressed this by routing all executions through the `Timelock` contract. Once a proposal is queued, it must sit for at least one full day before `execute()` can be called. The timelock checks `block.timestamp >= eta` and reverts with `"Timelock not ready"` if someone tries to jump the queue. This gives the community a window to react.

### 3. Double Execution and Proposal Replay

A valid concern is whether an already-executed proposal can be replayed. If the executed flag is never checked, the same proposal could drain the treasury multiple times.

In `ARESGovernance`, the `execute()` function checks `require(!p.executed, "Already executed")` before touching the timelock. The `cancelProposal()` function also sets `p.executed = true`, which means a cancelled proposal is treated identically to an executed one — it can never be rerun. My test `testCannotExecuteCancelledProposal` and `testCannotExecuteTwice` both confirm this behaviour holds.

### 4. Double Reward Claims

The reward distribution uses a Merkle tree to allow eligible addresses to claim 1 ETH each. The risk here is someone calling `claimReward()` repeatedly and draining the reward pool.

I handle this in `GovMerkleAuth` with a `claimed` mapping. Before any reward is paid out, `checkIfClaimed()` runs first. If the address has already claimed, it reverts with `"already claimed"`. The `markClaimed()` function then sets the flag before any transfer happens, following the checks-effects-interactions pattern to prevent reentrancy from being useful even if someone tried it.

### 5. Invalid Merkle Proof Submission

Anyone can call `claimReward()` with a made-up proof and try to collect rewards they are not entitled to. I use OpenZeppelin's `MerkleProof.verify()` under the hood through my `GovMerkle` library. The leaf is built as `keccak256(abi.encode(user))` and verified against the committed root. A proof that does not reconstruct the root reverts with `"invalid proof"`. My `testCannotClaimInvalidProof` test confirms a random address with a fabricated proof cannot claim.

### 6. Reentrancy on Reward Withdrawal

`withdrawReward()` in `ARESGovernance` sends ETH to the caller. If the caller is a contract with a malicious `receive()` function, it could try to re-enter `withdrawReward()` before the balance is zeroed.

I mitigate this by zeroing `rewards[msg.sender]` before calling `transfer()`. This means on any reentrant call, the balance is already zero and `require(amount > 0)` will revert it. The pattern is deliberate.

### 7. Insufficient Approval Threshold

A single compromised governor should not be able to push a proposal through alone. The approval threshold is calculated as 60% of the governor set, rounded up, using `(_governors.length * 60 + 99) / 100`. This means in a three-governor setup, at least two must approve before a proposal can be queued.

---

## Remaining Risks

**Root update mechanism is missing.** The Merkle root is set once at deployment and never updated. If new contributors need to be added to the reward set, there is currently no way to do that without redeploying the contract.

**Governors cannot be removed.** Once an address is added as a governor, there is no function to remove them. A compromised or malicious governor key remains a governor permanently.

**The timelock target call is unconstrained.** When `executeTxn` runs, it calls any target with any calldata. There is no allowlist of safe targets, which means a successful malicious proposal could call anything — including self-destruct on dependent contracts.

**No ETH balance check before reward payout.** If the contract runs out of ETH, `withdrawReward()` will fail silently or revert without a clear message, leaving users confused about whether their claim was lost.

These are known gaps that a production deployment would need to address before going live with real funds.