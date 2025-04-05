;; Title: BitOptions: sBTC-Powered Options Protocol
;; Summary: A Bitcoin-native options trading platform leveraging Stacks Layer 2 for secure, trustless derivatives
;; Description: 
;; BitOptions enables decentralized European-style options contracts collateralized 1:1 with sBTC. 
;; Built on Stacks with SIP-010 compliance, this protocol allows:
;; - Creation of call/put options with BTC-denominated strike prices
;; - Non-custodial sBTC collateral management
;; - Automated expiry settlement tied to Bitcoin block height
;; - Precision pricing with 8-decimal sBTC amounts
;; Combines Bitcoin's security with Stacks' smart contract capabilities to create the first native options market
;; for Bitcoin holders, by Bitcoin holders.

;; Define the trait for fungible tokens (SIP-010)
(define-trait ft-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-balance (principal) (response uint uint))
        (get-total-supply () (response uint uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
        (get-decimals () (response uint uint))
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-OPTION-NOT-FOUND (err u102))
(define-constant ERR-OPTION-EXPIRED (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-INVALID-STRIKE-PRICE (err u105))
(define-constant ERR-INVALID-EXPIRY (err u106))
(define-constant ERR-ALREADY-EXERCISED (err u107))
(define-constant ERR-INVALID-OPTION-TYPE (err u108))
(define-constant ERR-ZERO-AMOUNT (err u109))
(define-constant ERR-EXPIRY-TOO-SOON (err u110))
(define-constant ERR-NOT-EXPIRED (err u111))
(define-constant PRECISION u100000000) ;; 8 decimal places for BTC amounts
(define-constant MIN-EXPIRY-BLOCKS u144) ;; Minimum 1 day worth of blocks (assuming 10min/block)

;; Option Types
(define-constant OPTION-TYPE-CALL "CALL")
(define-constant OPTION-TYPE-PUT "PUT")

;; State Variables
(define-data-var next-option-id uint u1)
(define-data-var total-options-created uint u0)
(define-data-var total-options-exercised uint u0)

;; Data Maps
(define-map Options
    { option-id: uint }
    {
        writer: principal,
        holder: principal,
        option-type: (string-ascii 4),
        strike-price: uint,
        premium: uint,
        collateral: uint,
        expiry: uint,
        exercised: bool,
        created-at: uint
    }
)

(define-map UserBalances
    { user: principal }
    { balance: uint }
)

;; Private Functions
(define-private (is-valid-option-type (option-type (string-ascii 4)))
    (or 
        (is-eq option-type OPTION-TYPE-CALL)
        (is-eq option-type OPTION-TYPE-PUT)
    )
)

(define-private (transfer-sbtc (token <ft-trait>) (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        (contract-call? token transfer amount sender recipient none)
    )
)

(define-private (check-expiry (expiry uint))
    (let
        ((min-expiry (+ block-height MIN-EXPIRY-BLOCKS)))
        (asserts! (>= expiry min-expiry) ERR-EXPIRY-TOO-SOON)
        (asserts! (> expiry block-height) ERR-OPTION-EXPIRED)
        (ok true)
    )
)

(define-private (validate-strike-price (strike-price uint))
    (begin
        (asserts! (> strike-price u0) ERR-INVALID-STRIKE-PRICE)
        (ok true)
    )
)

(define-private (validate-amounts (premium uint) (collateral uint))
    (begin
        (asserts! (> premium u0) ERR-ZERO-AMOUNT)
        (asserts! (> collateral u0) ERR-ZERO-AMOUNT)
        (ok true)
    )
)

;; Read-Only Functions
(define-read-only (get-option (option-id uint))
    (map-get? Options { option-id: option-id })
)

(define-read-only (get-user-balance (user principal))
    (default-to 
        { balance: u0 }
        (map-get? UserBalances { user: user })
    )
)

(define-read-only (get-current-price)
    u50000000000) ;; $50,000 with 8 decimal places

(define-read-only (get-contract-stats)
    {
        total-options: (var-get total-options-created),
        exercised-options: (var-get total-options-exercised),
        next-id: (var-get next-option-id)
    }
)

;; Public Functions
(define-public (create-option (sbtc-token <ft-trait>) (option-type (string-ascii 4)) (strike-price uint) (premium uint) (collateral uint) (expiry uint))
    (let
        (
            (option-id (var-get next-option-id))
            (current-height block-height)
        )
        ;; Input validation
        (asserts! (is-valid-option-type option-type) ERR-INVALID-OPTION-TYPE)
        (try! (validate-strike-price strike-price))
        (try! (validate-amounts premium collateral))
        (try! (check-expiry expiry))
        
        ;; Transfer collateral from writer to contract
        (try! (transfer-sbtc sbtc-token collateral tx-sender (as-contract tx-sender)))
        
        ;; Create new option
        (map-set Options
            { option-id: option-id }
            {
                writer: tx-sender,
                holder: tx-sender,
                option-type: option-type,
                strike-price: strike-price,
                premium: premium,
                collateral: collateral,
                expiry: expiry,
                exercised: false,
                created-at: current-height
            }
        )
        
        ;; Update contract state
        (var-set next-option-id (+ option-id u1))
        (var-set total-options-created (+ (var-get total-options-created) u1))
        
        (ok option-id)
    )
)