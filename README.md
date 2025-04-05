# BitOptions Protocol Documentation

## Overview

BitOptions is a decentralized options trading protocol built on Bitcoin via the Stacks Layer 2 network. The protocol enables non-custodial, European-style options contracts collateralized 1:1 with sBTC, combining Bitcoin's security with advanced smart contract capabilities.

### Key Features

- **Bitcoin-Native Derivatives**: Fully collateralized options settled in sBTC
- **European Exercise Style**: Options exercisable only at expiration
- **Trustless Settlement**: Automated execution via Bitcoin block height triggers
- **Precision Trading**: 8-decimal granularity for BTC amounts
- **SIP-010 Compliance**: Interoperable with Stacks token standards
- **Non-Custodial**: Users maintain control of assets until settlement

## Technical Specifications

### Core Parameters

| Parameter           | Value       | Description                         |
| ------------------- | ----------- | ----------------------------------- |
| `PRECISION`         | 100,000,000 | 8-decimal precision for BTC amounts |
| `MIN-EXPIRY-BLOCKS` | 144         | ~24 hours (10 min/block)            |
| `OPTION-TYPE-CALL`  | "CALL"      | Right to buy at strike price        |
| `OPTION-TYPE-PUT`   | "PUT"       | Right to sell at strike price       |

### Contract Architecture

#### Data Structures

```clarity
;; Option Contract Structure
{
    writer: principal,    ;; Option seller
    holder: principal,    ;; Option buyer
    option-type: string,  ;; CALL/PUT
    strike-price: uint,   ;; BTC-denominated in satoshis
    premium: uint,        ;; sBTC payment for option
    collateral: uint,     ;; sBTC locked by writer
    expiry: uint,         ;; Bitcoin block height
    exercised: bool,      ;; Execution status
    created-at: uint      ;; Creation block height
}
```

#### State Management

- `next-option-id`: Auto-incrementing option identifier
- `total-options-created`: Lifetime option count
- `total-options-exercised`: Lifetime exercised contracts

## Smart Contract Functions

### Core Operations

#### `create-option`

Initializes new options contract

```clarity
(create-option sbtc-token option-type strike-price premium collateral expiry)
```

- **Parameters**:
  - `sbtc-token`: SIP-010 compliant token contract
  - `option-type`: CALL/PUT
  - `strike-price`: BTC price in satoshis (1e8 precision)
  - `premium`: sBTC amount paid by buyer
  - `collateral`: sBTC locked by writer
  - `expiry`: Bitcoin block height

#### `buy-option`

Transfers option ownership

```clarity
(buy-option sbtc-token option-id)
```

- Transfers premium from buyer to writer
- Updates option holder to buyer

#### `exercise-option`

Executes in-the-money options

```clarity
(exercise-option sbtc-token option-id)
```

- Validates current price against strike
- Transfers collateral to holder
- Marks option as exercised

#### `expire-option`

Expires worthless contracts

```clarity
(expire-option sbtc-token option-id)
```

- Returns collateral to writer
- Only callable post-expiry

### Price Oracle

```clarity
(define-read-only (get-current-price) ...)
```

_Note: Current implementation uses mock data. Production deployment requires decentralized oracle integration._

## Usage Guide

### Workflow Overview

1. **Option Creation**

   - Writer specifies terms and locks collateral
   - System generates unique option ID

2. **Secondary Trading**

   - Original holder transfers option rights
   - Premium automatically settles between parties

3. **Expiration Handling**
   - In-the-money: Holder exercises for collateral
   - Out-of-money: Writer reclaims collateral

### Example Scenario: Bullish Call Option

1. Alice locks 1 sBTC collateral to sell 50,000 sats CALL
2. Bob buys option for 0.1 sBTC premium
3. At expiry:
   - If BTC > 50k: Bob exercises for 1 sBTC profit
   - If BTC ≤ 50k: Alice reclaims 1 sBTC

## Security Model

### Error Codes

| Code | Description             |
| ---- | ----------------------- |
| u100 | Unauthorized access     |
| u101 | Invalid monetary amount |
| u102 | Nonexistent option      |
| u103 | Expired contract        |
| u104 | Insufficient balance    |
| u105 | Invalid strike price    |
| u106 | Invalid expiry time     |
| u107 | Already exercised       |
| u108 | Invalid option type     |
| u109 | Zero amount prohibited  |
| u110 | Expiry too near         |
| u111 | Not yet expired         |

### Critical Safeguards

1. **Collateral Verification**

   - Full sBTC lock before option activation
   - Direct transfers bypassing balance checks prohibited

2. **Temporal Security**

   - Minimum 144-block (≈24h) expiry floor
   - Bitcoin block height as immutable clock

3. **Financial Integrity**
   - 8-decimal precision for all monetary values
   - Strict type enforcement for sBTC amounts

## Dependencies

- Stacks Blockchain (Layer 2)
- SIP-010 Compliant sBTC Token
- Bitcoin Network (Settlement layer)
