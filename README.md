# BitAsset Exchange Protocol - Smart Contract Documentation

## Overview

BitAsset Exchange is a decentralized marketplace protocol built on Stacks (Bitcoin Layer 2) enabling secure peer-to-peer trading of digital content assets. This implementation consists of a Clarity smart contract managing:

- Content lifecycle management
- STX-based transactions
- Trader reputation system
- Bitcoin-anchored audit trails

## Key Features

### 1. Content Management System

- NFT-like registration with metadata
- Dynamic price adjustments
- Owner-controlled listing status
- Content-type validation (64 char limit)
- Secure access token storage

### 2. Trading Engine

- STX payment processing
- Automated fee distribution (3% default)
- Anti self-trading protection
- Transaction history tracking
- Block height-based timestamps

### 3. Reputation Framework

- Trade count tracking
- Activity recency monitoring
- Quality scoring (placeholder implementation)
- Merchant performance analytics

### 4. Compliance Architecture

- Bitcoin-block anchored records
- Immutable ownership history
- Transaction audit trails
- Layer 2 regulatory compatibility

## Technical Specifications

### Smart Contract Details

- Language: Clarity v2.1
- Compatibility: Stacks 2.1+, Bitcoin SegWit
- Data Models: 4 persistent maps
- State Variables: 3 global counters
- Error Codes: 7 custom exceptions

### Core Data Structures

1. `content-offerings`: Digital asset registry

   - Owner principal
   - Price (uint)
   - Content metadata
   - Availability status

2. `trader-metrics`: Participant reputation

   - Trade count
   - Quality score
   - Last activity block

3. `exchange-records`: Transaction ledger

   - Buyer/seller principals
   - Transfer details
   - Bitcoin block correlation

4. `content-keys`: Encrypted access control
   - 512-char token storage
   - Item-ID indexed

## System Operations

### Content Lifecycle Workflow

1. Registration:

   - Generate unique content ID
   - Store metadata + access token
   - Initialize tradeable status

2. Price Update:

   - Owner authentication
   - > 0 STX validation
   - Market availability check

3. Purchase:

   - STX balance verification
   - Fee calculation/distribution
   - Access token transfer
   - Reputation update

4. Delisting:
   - Ownership verification
   - Status toggle
   - Historical preservation

## Security Model

### Assurance Mechanisms

- Principal-based access control
- Input validation layers
  - String length checks
  - Price >0 enforcement
  - ID existence verification
- Transfer rollback protection
- Self-trade prevention

### Risk Mitigations

- Reentrancy protection (Clarity inherent)
- Overflow protection (uint type)
- Data encapsulation
- Explicit error states

## Developer Guide

### Contract Interface

**Core Functions:**

- `register-content`: (price, metadata, token) → content-ID
- `acquire-content`: (content-ID) → transaction-status
- `modify-price`: (content-ID, new-price) → confirmation
- `delist-content`: (content-ID) → status

**Query Endpoints:**

- `get-content-info`: Content metadata retrieval
- `get-trader-info`: Reputation analytics
- `get-exchange-stats`: Platform KPIs

### Testing Matrix

1. Content registration

   - Valid metadata
   - Duplicate prevention
   - Counter increment

2. Purchase validation

   - Sufficient balance
   - Fee calculation
   - Reputation update

3. Access control
   - Ownership verification
   - Delisted content access
   - Historical records

## Compliance Features

### Bitcoin Integration

- STX transfers (BTC-backed)
- Block height tracking
  - Content creation time
  - Transaction timestamp
  - Last activity marker
- Audit trail immutability

### Regulatory Alignment

- Permanent ownership history
- Pseudonymous trading
- Fee transparency
- Irreversible transactions

## Local Deployment

### Requirements

- Clarinet SDK 1.5.0+
- Stacks-node testnet config
- STX testnet faucet

### Installation

1. Clone repository
2. Configure Clarinet.toml
3. Start local devnet:
   ```bash
   clarinet integrate
   ```

## Contribution Guidelines

- Fork repository
- Create feature branch
- Add test coverage
- Submit PR with:
  - Technical spec
  - Audit checklist
  - Integration tests
