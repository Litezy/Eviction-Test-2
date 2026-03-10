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

## Wrap Up

The modular design keeps each responsibility separate. This reduces the attack surface and makes it easier to upgrade or swap out parts of the system if needed.

