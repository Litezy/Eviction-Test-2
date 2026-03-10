# ARES Governance Architecture

This doc explains how the ARES governance system is built and organized.

## System Overview

ARES Governance is a modular system for managing treasury proposals, approving changes, and distributing rewards to verified governors. The system is broken into three main layers:

- **Core** - handles main governance logic
- **Interfaces** - handles specific function calls
- **Modules** - provides specific features
- **Libraries** - reusable utility code

This separation makes the system easier to maintain, test, and secure.

## Main Components

### Core Contract (ARES Governance)

The core contract runs the show. It:

- Manages proposals from start to finish
- Tracks approvals from governors
- Handles queuing and execution
- Works with timelock and treasury modules
- Keeps track of governor rewards
- Integrates Merkle verification for reward claims

### Treasury Module

The treasury handles all fund-related stuff:

- Manages fund allocation
- Queues treasury transactions
- Executes transactions after approvals are met
- Works with timelock to enforce delays

### GovGuard Module

This module takes care of permissions:

- Manages who is a governor
- Enforces access control rules
- Only allows authorized addresses to create or approve proposals

### GovMerkleAuth Module

This handles reward claims:

- Verifies Merkle proofs
- Makes sure only whitelisted users can claim
- Stops people from claiming twice

## Libraries

### GovMerkle Library

This library gives us Merkle proof verification without storing the full whitelist on-chain. Pretty handy for keeping gas costs down.

## Security Design

### Access Control

Only governors can create and approve proposals. The GovGuard module makes sure this rule is always followed.

### Merkle Verification

Reward claims need valid Merkle proofs. This keeps out unauthorized users and stops replay attacks.

### Timelock

Queued proposals wait before they can run. This delay stops anyone from making quick, unchecked changes to the treasury.

## Trust Model

A few things to keep in mind:

- Governors are trusted to do the right thing
- The system requires multiple approvals to reduce single-point-of-failure risks
- The timelock is trusted to enforce delays correctly
- The Merkle root used at deployment needs to be correct


# Security Analysis

This document covers the  security considerations for the ARES governance system.

## Potential Attack Vectors

### Proposal Manipulation

Bad actors might try to create, approve, queue, or execute harmful proposals.

**How we handle it:**
- Only governors can use these functions
- Multiple governors must approve before execution
- Timelock adds a delay to catch any issues

### Reward Exploitation

Someone could try to claim rewards twice or use fake Merkle proofs.

**How we handle it:**
- GovMerkleAuth keeps track of who has claimed
- Merkle proof verification only lets eligible users claim
- Double claims get reverted

### Reentrancy Issues

Treasury actions could be exploited if external calls happen at the wrong time.

**How we handle it:**
- No external calls before state changes
- Funds move only through controlled treasury functions
- All state updates happen first

### Premature Execution

An attacker might try to run a proposal before the timelock delay ends.

**How we handlen it:**
- Timelock strictly enforces the waiting period
- A governor can use the cancel proposal function to cancel a proposal so it does'nt get executed
- Execution only works after eta is reached

### Replay Attacks

Running the same proposal multiple times could drain funds.

**How we handle it:**
- Proposal status is tracked after execution
- Only unexecuted proposals can run
- Governors can cancel proposals before execution if problems are found

## Trust Considrations

The system has protections against common attacks, but some trust is still required:

- **Governor integrity** - governors should act in the protocol's best interest
- **Deployment correctness** - the initial setup must be done properly
- **Merkle root accuracy** - the whitelist must be correct at deploy time

## Summaryy

The system has solid defenses against:
- Double claimss
- Unauthorized execution
- Replay attacks
- Reentrancy exploits

Most risks come down to trusting that governors will act honestly and that the initial deployment is done right.

*For more details on the security of this contract, check out SECURITY.md*



