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