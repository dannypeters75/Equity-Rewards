# Equity-Based Profit Distribution Smart Contract

A comprehensive blockchain-based system for automated profit sharing among equity holders built on the Stacks blockchain using Clarity smart contract language.

## Overview

This smart contract enables transparent, secure, and programmable distribution of profits based on predetermined ownership percentages. It features multi-round distribution cycles, stakeholder access control, comprehensive claim tracking, and emergency management capabilities.

## Key Features

- **Precision Equity Management**: Uses basis points (0.01% granularity) for precise ownership calculations
- **Automated Distribution Rounds**: Structured profit distribution with complete audit trail
- **Access Control**: Stakeholder blacklisting and permission management
- **Transparent Tracking**: Complete history of claims and balance accumulation
- **Emergency Controls**: Owner-controlled emergency withdrawal capabilities
- **Comprehensive Validation**: Robust input validation and security protocols

## Contract Architecture

### Core Components

1. **Stakeholder Management**: Register, update, and remove equity holders
2. **Distribution Rounds**: Manage profit distribution cycles
3. **Contribution System**: Accept STX contributions for profit sharing
4. **Claim Mechanism**: Allow stakeholders to claim their allocated profits
5. **Access Control**: Blacklist management and permission systems

### Data Structures

- **Stakeholder Equity Records**: Maps principals to ownership percentages
- **Balance Ledger**: Tracks accumulated balances for each stakeholder
- **Distribution History**: Complete record of all distribution rounds
- **Claim Tracking**: Prevents double-claiming of profits
- **Access Control**: Blacklist management for stakeholders

## Getting Started

### Prerequisites

- Stacks blockchain testnet/mainnet access
- Clarity CLI or compatible development environment
- STX tokens for testing and deployment

### Deployment

1. Deploy the contract to the Stacks blockchain
2. Initialize the contract with minimum stake threshold
3. Register stakeholders with their ownership percentages
4. Start accepting contributions and managing distribution rounds

### Basic Usage Flow

```clarity
;; 1. Initialize the contract (owner only)
(contract-call? .equity-contract initialize-contract u1000000) ;; 1 STX minimum

;; 2. Register stakeholders (owner only)
(contract-call? .equity-contract register-stakeholder 'SP1... u2500) ;; 25% ownership

;; 3. Start distribution round (owner only)
(contract-call? .equity-contract start-distribution-round)

;; 4. Contributors send STX
(contract-call? .equity-contract contribute-stx-amount u1000000)

;; 5. Execute profit distribution (owner only)
(contract-call? .equity-contract execute-profit-distribution)

;; 6. Stakeholders claim profits
(contract-call? .equity-contract claim-profits u1) ;; Round 1
```

## Function Reference

### Initialization Functions

#### `initialize-contract`
```clarity
(define-public (initialize-contract (minimum-stake-amount uint))
```
**Description**: Initializes the contract with minimum stake threshold
**Access**: Owner only
**Parameters**: 
- `minimum-stake-amount`: Minimum STX amount for stakes (in microSTX)

### Stakeholder Management

#### `register-stakeholder`
```clarity
(define-public (register-stakeholder (stakeholder-address principal) (ownership-percentage uint))
```
**Description**: Registers a new stakeholder with ownership percentage
**Access**: Owner only
**Parameters**:
- `stakeholder-address`: Principal address of the stakeholder
- `ownership-percentage`: Ownership in basis points (1-10000)

#### `update-stakeholder-ownership`
```clarity
(define-public (update-stakeholder-ownership (stakeholder-address principal) (new-ownership-percentage uint))
```
**Description**: Updates existing stakeholder's ownership percentage
**Access**: Owner only

#### `remove-stakeholder`
```clarity
(define-public (remove-stakeholder (stakeholder-address principal))
```
**Description**: Removes a stakeholder from the contract
**Access**: Owner only

### Distribution Round Management

#### `start-distribution-round`
```clarity
(define-public (start-distribution-round))
```
**Description**: Begins a new profit distribution round
**Access**: Owner only

#### `end-distribution-round`
```clarity
(define-public (end-distribution-round))
```
**Description**: Ends the current distribution round
**Access**: Owner only

#### `execute-profit-distribution`
```clarity
(define-public (execute-profit-distribution))
```
**Description**: Executes profit distribution and creates a new round
**Access**: Owner only
**Returns**: New round ID

### Contribution Functions

#### `contribute-stx-amount`
```clarity
(define-public (contribute-stx-amount (contribution-amount uint))
```
**Description**: Contributes a specific amount of STX to the contract
**Access**: Public (during active distribution rounds)
**Parameters**:
- `contribution-amount`: Amount of STX to contribute (in microSTX)

#### `contribute-all-stx`
```clarity
(define-public (contribute-all-stx))
```
**Description**: Contributes all available STX from sender's wallet
**Access**: Public (during active distribution rounds)

### Profit Claims

#### `claim-profits`
```clarity
(define-public (claim-profits (target-round-id uint))
```
**Description**: Claims profits for a specific distribution round
**Access**: Registered stakeholders only
**Parameters**:
- `target-round-id`: ID of the distribution round to claim from

### Access Control

#### `blacklist-stakeholder`
```clarity
(define-public (blacklist-stakeholder (stakeholder-address principal))
```
**Description**: Adds a stakeholder to the blacklist
**Access**: Owner only

#### `remove-stakeholder-from-blacklist`
```clarity
(define-public (remove-stakeholder-from-blacklist (stakeholder-address principal))
```
**Description**: Removes a stakeholder from the blacklist
**Access**: Owner only

### Emergency Functions

#### `emergency-withdraw-all-funds`
```clarity
(define-public (emergency-withdraw-all-funds))
```
**Description**: Withdraws all contract funds to the owner
**Access**: Owner only
**Use Case**: Emergency situations only

## Read-Only Functions

### Stakeholder Information
- `get-stakeholder-equity-info`: Get ownership percentage for a stakeholder
- `get-stakeholder-balance`: Get accumulated balance for a stakeholder
- `has-claimed-profits`: Check if profits were claimed for a specific round
- `is-stakeholder-blacklisted`: Check blacklist status

### Contract Status
- `get-contract-initialization-status`: Check if contract is initialized
- `is-distribution-round-active`: Check if distribution round is active
- `get-current-round-number`: Get current distribution round number
- `get-total-allocated-percentage`: Get total percentage allocated to stakeholders
- `get-available-contract-balance`: Get current contract STX balance

### Calculations
- `calculate-stakeholder-profit-share`: Calculate profit share for a stakeholder in a round
- `get-comprehensive-contract-status`: Get complete contract status overview

## Error Codes

### Access Control & Authorization (100s)
- `ERR-UNAUTHORIZED-ACCESS` (100): Caller lacks required permissions
- `ERR-STAKEHOLDER-BLACKLISTED` (101): Stakeholder is blacklisted
- `ERR-INVALID-CALLER-PERMISSIONS` (102): Invalid caller permissions

### Contract State (200s)
- `ERR-CONTRACT-ALREADY-INITIALIZED` (200): Contract already initialized
- `ERR-CONTRACT-NOT-INITIALIZED` (201): Contract not yet initialized
- `ERR-INVALID-CONTRACT-STATE` (202): Invalid contract state

### Input Validation (300s)
- `ERR-INVALID-PERCENTAGE-VALUE` (300): Percentage value exceeds 100%
- `ERR-INVALID-MINIMUM-STAKE-AMOUNT` (301): Invalid minimum stake amount
- `ERR-INVALID-PRINCIPAL-ADDRESS` (302): Invalid principal address
- `ERR-ZERO-AMOUNT-PROVIDED` (303): Zero amount provided
- `ERR-INVALID-ROUND-IDENTIFIER` (304): Invalid round identifier

### Business Logic (400s)
- `ERR-TOTAL-PERCENTAGE-EXCEEDED` (400): Total percentage would exceed 100%
- `ERR-STAKEHOLDER-NOT-REGISTERED` (401): Stakeholder not registered
- `ERR-INSUFFICIENT-OWNERSHIP-STAKE` (402): Insufficient ownership stake
- `ERR-DISTRIBUTION-ROUND-ACTIVE` (403): Distribution round currently active
- `ERR-DISTRIBUTION-ROUND-INACTIVE` (404): Distribution round not active
- `ERR-PROFITS-ALREADY-CLAIMED` (405): Profits already claimed for this round
- `ERR-STAKEHOLDER-ALREADY-EXISTS` (406): Stakeholder already registered

### Financial Operations (500s)
- `ERR-INSUFFICIENT-CONTRACT-BALANCE` (500): Insufficient contract balance
- `ERR-TRANSFER-FAILED` (501): STX transfer failed
- `ERR-INSUFFICIENT-USER-BALANCE` (502): Insufficient user balance

## Security Considerations

1. **Owner Controls**: The contract owner has significant control over stakeholder management and emergency functions
2. **Access Control**: Stakeholders can be blacklisted to prevent claims
3. **Validation**: Comprehensive input validation prevents invalid operations
4. **Double Spending**: Claim tracking prevents multiple claims for the same round
5. **Emergency Withdrawal**: Owner can withdraw all funds in emergency situations

## Best Practices

1. **Initialization**: Always initialize the contract before registering stakeholders
2. **Percentage Management**: Ensure total ownership percentages don't exceed 100%
3. **Distribution Rounds**: Only start distribution rounds when ready to accept contributions
4. **Claim Timing**: Stakeholders should claim profits promptly after distribution
5. **Emergency Use**: Use emergency withdrawal only in critical situations