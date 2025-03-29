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

;; Submit Application
(define-public (submit-application 
    (pool-id uint)
    (requested-amount uint)
    (phases (list 5 {
        description: (string-ascii 100),
        amount: uint,
        completed: bool
    })))
    (let
        (
            (application-id (+ (var-get current-application-id) u1))
            (pool (unwrap! (map-get? funding-pools { pool-id: pool-id }) err-not-found))
        )
        ;; Validate pool id and state
        (asserts! (validate-pool-id pool-id) err-not-found)
        (asserts! (get active pool) err-invalid-state)
        ;; Validate requested amount
        (asserts! (validate-amount requested-amount) err-invalid-amount)
        (asserts! (<= requested-amount (get remaining-amount pool)) err-insufficient-funds)
        ;; Validate phases
        (asserts! (validate-phases phases) err-invalid-phase)
        
        (map-set applications
            { application-id: application-id }
            {
                applicant: tx-sender,
                pool-id: pool-id,
                requested-amount: requested-amount,
                status: "pending",
                phases: phases
            }
        )
        (var-set current-application-id application-id)
        (ok application-id)
    )
)

;; Get vote count for an application
(define-read-only (get-vote-counts (application-id uint))
    (ok (default-to 
        { positive-count: u0, total-count: u0 }
        (map-get? vote-tallies { application-id: application-id })
    ))
)

;; Vote on Application
(define-public (vote-on-application (application-id uint) (in-favor bool))
    (let
        (
            ;; First validate the application-id
            (valid-id (asserts! (validate-application-id application-id) err-not-found))
            (application (unwrap! (map-get? applications { application-id: application-id }) err-not-found))
            (current-tally (default-to 
                { positive-count: u0, total-count: u0 }
                (map-get? vote-tallies { application-id: application-id })))
        )
        ;; Validate application state
        (asserts! (is-eq (get status application) "pending") err-invalid-state)
        ;; Check if voter has already voted
        (asserts! (is-none (map-get? votes { application-id: application-id, voter: tx-sender })) err-invalid-state)
        
        ;; Record the vote
        (map-set votes
            { application-id: application-id, voter: tx-sender }
            { in-favor: in-favor }
        )

        ;; Update vote tally
        (map-set vote-tallies
            { application-id: application-id }
            {
                positive-count: (if in-favor 
                    (+ (get positive-count current-tally) u1)
                    (get positive-count current-tally)),
                total-count: (+ (get total-count current-tally) u1)
            }
        )
        (ok true)
    )
)

;; Complete Phase
(define-public (complete-phase (application-id uint) (phase-index uint))
    (let
        (
            ;; First validate the application-id
            (valid-id (asserts! (validate-application-id application-id) err-not-found))
            (application (unwrap! (map-get? applications { application-id: application-id }) err-not-found))
            (pool (unwrap! (map-get? funding-pools { pool-id: (get pool-id application) }) err-not-found))
        )
        ;; Validate application state
        (asserts! (is-eq (get status application) "approved") err-invalid-state)
        ;; Validate user is the applicant
        (asserts! (is-eq tx-sender (get applicant application)) err-unauthorized)
        ;; Validate phase index
        (asserts! (< phase-index (len (get phases application))) err-invalid-phase)
        
        (ok true)
    )
)

;; Approve or Reject Application
(define-public (finalize-application (application-id uint))
    (let
        (
            ;; First validate the application-id
            (valid-id (asserts! (validate-application-id application-id) err-not-found))
            (application (unwrap! (map-get? applications { application-id: application-id }) err-not-found))
            (pool (unwrap! (map-get? funding-pools { pool-id: (get pool-id application) }) err-not-found))
            (vote-tally (default-to 
                { positive-count: u0, total-count: u0 }
                (map-get? vote-tallies { application-id: application-id })))
        )
        ;; Check permissions
        (asserts! (is-eq tx-sender (get owner pool)) err-owner-only)
        ;; Check application is pending
        (asserts! (is-eq (get status application) "pending") err-invalid-state)
        ;; Check minimum votes
        (asserts! (>= (get total-count vote-tally) (var-get minimum-votes-required)) err-insufficient-votes)
        ;; Check if there are any votes
        (asserts! (> (get total-count vote-tally) u0) err-no-votes)
        
        ;; Calculate if application is approved (more than quorum threshold)
        (if (>= (get positive-count vote-tally) 
            (/ (* (get total-count vote-tally) (var-get quorum-threshold)) u100))
            ;; Approve application
            (begin
                (map-set applications
                    { application-id: application-id }
                    (merge application { status: "approved" })
                )
                ;; Update pool remaining amount
                (map-set funding-pools
                    { pool-id: (get pool-id application) }
                    (merge pool 
                        { remaining-amount: (- (get remaining-amount pool) (get requested-amount application)) }
                    )
                )
                (ok true)
            )
            ;; Reject application
            (begin
                (map-set applications
                    { application-id: application-id }
                    (merge application { status: "rejected" })
                )
                (ok true)
            )
        )
    )
)