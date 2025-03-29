;; GrantHub Grant Distribution Platform Smart Contract

;; Define SIP-010 Fungible Token Trait
(define-trait ft-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
        (get-decimals () (response uint uint))
        (get-balance (principal) (response uint uint))
        (get-total-supply () (response uint uint))
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-state (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-token (err u106))
(define-constant err-invalid-phase (err u107))
(define-constant err-insufficient-votes (err u108))
(define-constant err-no-votes (err u109))


;; Data Maps
(define-map funding-pools
    { pool-id: uint }
    {
        owner: principal,
        total-amount: uint,
        remaining-amount: uint,
        token-contract: principal,
        active: bool
    }
)

(define-map applications
    { application-id: uint }
    {
        applicant: principal,
        pool-id: uint,
        requested-amount: uint,
        status: (string-ascii 20),  ;; pending, approved, rejected, completed
        phases: (list 5 {
            description: (string-ascii 100),
            amount: uint,
            completed: bool
        })
    }
)

(define-map votes
    { application-id: uint, voter: principal }
    { in-favor: bool }
)

;; Vote tracking
(define-map vote-tallies
    { application-id: uint }
    {
        positive-count: uint,
        total-count: uint
    }
)


;; Data Variables
(define-data-var current-pool-id uint u0)
(define-data-var current-application-id uint u0)
(define-data-var minimum-funding-amount uint u1000000) ;; Set minimum funding amount
(define-data-var maximum-funding-amount uint u1000000000) ;; Set maximum funding amount
(define-data-var minimum-votes-required uint u3) ;; Minimum votes required for decision
(define-data-var quorum-threshold uint u50) ;; Percentage needed for approval (50%)

;; Private Functions
(define-private (validate-pool-id (pool-id uint))
    (<= pool-id (var-get current-pool-id))
)

(define-private (validate-application-id (application-id uint))
    (<= application-id (var-get current-application-id))
)

(define-private (validate-amount (amount uint))
    (and 
        (>= amount (var-get minimum-funding-amount))
        (<= amount (var-get maximum-funding-amount))
    )
)

(define-private (validate-phases (phases (list 5 {
    description: (string-ascii 100),
    amount: uint,
    completed: bool
})))
    (let
        (
            (total-phase-amount (fold + (map get-phase-amount phases) u0))
        )
        (> (len phases) u0)
    )
)

(define-private (get-phase-amount (phase {
    description: (string-ascii 100),
    amount: uint,
    completed: bool
}))
    (get amount phase)
)

;; Public Functions

;; Create Funding Pool
(define-public (create-funding-pool (total-amount uint) (token-contract <ft-trait>))
    (let
        (
            (pool-id (+ (var-get current-pool-id) u1))
            (token-principal (contract-of token-contract))
        )
        ;; Check permissions
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Validate amount
        (asserts! (validate-amount total-amount) err-invalid-amount)
        ;; Check token balance
        (asserts! 
            (is-ok (contract-call? token-contract get-balance tx-sender)) 
            err-invalid-token
        )
        
        (map-set funding-pools
            { pool-id: pool-id }
            {
                owner: tx-sender,
                total-amount: total-amount,
                remaining-amount: total-amount,
                token-contract: token-principal,
                active: true
            }
        )
        (var-set current-pool-id pool-id)
        (ok pool-id)
    )
)
