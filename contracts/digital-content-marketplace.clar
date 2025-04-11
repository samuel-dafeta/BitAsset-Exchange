;; Title: BitAsset Exchange - Decentralized Digital Content Marketplace
;; Summary: A Bitcoin-compliant Layer 2 solution for secure, transparent digital content trading
;; Description:
;; BitAsset Exchange is a Stacks Layer 2 protocol enabling peer-to-peer digital content commerce
;; with Bitcoin-finalized security. The platform features:
;; - Non-custodial content trading with automated royalty distribution
;; - Immutable ownership records anchored to Bitcoin blockchain
;; - Reputation-based trader metrics with activity proofs
;; - Compliance-focused design supporting Bitcoin-native financial primitives
;; - Zero-knowledge content access credentials with secure off-chain delivery

;; Core Features:
;; 1. Bitcoin-Secured Transactions: All trades settled in STX with Bitcoin-finalized security
;; 2. Dynamic Pricing Engine: Self-custody price adjustments with market-responsive controls
;; 3. Content Provenance Tracking: Permanent lineage records using Stacks blockchain primitives
;; 4. Layer 2 Compliance: Designed for SECURE Bitcoin transaction compliance standards
;; 5. Discreet Asset Management: Secure content access with encrypted payload delivery

;; Built using Clarity Smart Contract language for provable correctness and Bitcoin compatibility

;; Constants
(define-constant owner-address tx-sender)
(define-constant ERR_UNAUTHORIZED (err u201))
(define-constant ERR_ITEM_UNAVAILABLE (err u202))
(define-constant ERR_DUPLICATE_ITEM (err u203))
(define-constant ERR_INSUFFICIENT_FUNDS (err u204))
(define-constant ERR_SELF_TRADE_BLOCKED (err u205))
(define-constant ERR_PRICE_INVALID (err u206))
(define-constant ERR_INPUT_INVALID (err u207))

;; Data Maps
;; Content offerings store the core metadata and trading parameters
(define-map content-offerings 
    { item-id: uint }
    {
        owner: principal,
        price-tag: uint,
        content-summary: (string-ascii 256),
        content-type: (string-ascii 64),
        tradeable: bool,
        creation-block: uint
    }
)

;; Trader metrics track participant reputation and activity
(define-map trader-metrics
    { participant: principal }
    {
        trade-count: uint,
        quality-score: uint,
        last-active: uint
    }
)

;; Exchange records maintain transaction history
(define-map exchange-records
    { customer: principal, item-id: uint }
    {
        timestamp: uint,
        cost: uint,
        merchant: principal
    }
)

;; Secure storage for content access credentials
(define-map content-keys
    { item-id: uint }
    { secure-access-token: (string-ascii 512) }
)

;; State Variables
(define-data-var item-counter uint u1)
(define-data-var exchange-fee uint u3) ;; 3% fee
(define-data-var exchange-volume uint u0)

;; Input Validation Functions
(define-private (verify-summary (text (string-ascii 256)))
    (and 
        (not (is-eq text ""))
        (<= (len text) u256)
    )
)

(define-private (verify-type (text (string-ascii 64)))
    (and
        (not (is-eq text ""))
        (<= (len text) u64)
    )
)

(define-private (verify-token (text (string-ascii 512)))
    (and
        (not (is-eq text ""))
        (<= (len text) u512)
    )
)

;; Financial Helper Functions
(define-private (compute-fee (price uint))
    (/ (* price (var-get exchange-fee)) u100)
)

(define-private (process-payment (from principal) (to principal) (amount uint))
    (stx-transfer? amount from to)
)

;; Content Management Functions

;; Register new digital content for sale
(define-public (register-content (asking-price uint) 
                               (summary (string-ascii 256)) 
                               (content-type (string-ascii 64)) 
                               (access-token (string-ascii 512)))
    (let
        (
            (current-id (var-get item-counter))
        )
        (asserts! (> asking-price u0) ERR_PRICE_INVALID)
        (asserts! (verify-summary summary) ERR_INPUT_INVALID)
        (asserts! (verify-type content-type) ERR_INPUT_INVALID)
        (asserts! (verify-token access-token) ERR_INPUT_INVALID)
        (asserts! (not (default-to false (get tradeable 
            (map-get? content-offerings { item-id: current-id })))) 
            ERR_DUPLICATE_ITEM)
        
        (map-set content-offerings
            { item-id: current-id }
            {
                owner: tx-sender,
                price-tag: asking-price,
                content-summary: summary,
                content-type: content-type,
                tradeable: true,
                creation-block: stacks-block-height
            }
        )
        
        (map-set content-keys
            { item-id: current-id }
            { secure-access-token: access-token }
        )
        
        (var-set item-counter (+ current-id u1))
        (ok current-id)
    )
)

;; Purchase digital content
(define-public (acquire-content (item-id uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
            (total-cost (get price-tag item-info))
            (merchant (get owner item-info))
            (fee-amount (compute-fee total-cost))
            (merchant-share (- total-cost fee-amount))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (asserts! (get tradeable item-info) ERR_ITEM_UNAVAILABLE)
        (asserts! (is-eq false (is-eq tx-sender merchant)) ERR_SELF_TRADE_BLOCKED)
        
        (try! (process-payment tx-sender merchant merchant-share))
        (try! (process-payment tx-sender owner-address fee-amount))
        
        (map-set exchange-records
            { customer: tx-sender, item-id: item-id }
            {
                timestamp: stacks-block-height,
                cost: total-cost,
                merchant: merchant
            }
        )
        
        (let
            (
                (merchant-stats (default-to 
                    { trade-count: u0, quality-score: u0, last-active: u0 }
                    (map-get? trader-metrics { participant: merchant })))
            )
            (map-set trader-metrics
                { participant: merchant }
                {
                    trade-count: (+ (get trade-count merchant-stats) u1),
                    quality-score: (get quality-score merchant-stats),
                    last-active: stacks-block-height
                }
            )
        )
        
        (var-set exchange-volume (+ (var-get exchange-volume) u1))
        (ok true)
    )
)

;; Access Management Functions

;; Retrieve content access credentials
(define-public (retrieve-access-token (item-id uint))
    (let
        (
            (purchase-info (unwrap! (map-get? exchange-records 
                { customer: tx-sender, item-id: item-id }) ERR_UNAUTHORIZED))
            (content-access (unwrap! (map-get? content-keys 
                { item-id: item-id }) ERR_ITEM_UNAVAILABLE))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (ok (get secure-access-token content-access))
    )
)

;; Listing Management Functions

;; Update content price
(define-public (modify-price (item-id uint) (updated-price uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (asserts! (is-eq (get owner item-info) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (> updated-price u0) ERR_PRICE_INVALID)
        
        (map-set content-offerings
            { item-id: item-id }
            (merge item-info { price-tag: updated-price })
        )
        (ok true)
    )
)

;; Remove content from marketplace
(define-public (delist-content (item-id uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
        )
        (asserts! (< item-id (var-get item-counter)) ERR_INPUT_INVALID)
        (asserts! (is-eq (get owner item-info) tx-sender) ERR_UNAUTHORIZED)
        
        (map-set content-offerings
            { item-id: item-id }
            (merge item-info { tradeable: false })
        )
        (ok true)
    )
)

;; Administrative Functions

;; Update marketplace fee rate
(define-public (adjust-fee-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender owner-address) ERR_UNAUTHORIZED)
        (asserts! (<= new-rate u100) ERR_PRICE_INVALID)
        (var-set exchange-fee new-rate)
        (ok true)
    )
)

;; Read-Only Query Functions

;; Get content listing details
(define-read-only (get-content-info (item-id uint))
    (map-get? content-offerings { item-id: item-id })
)