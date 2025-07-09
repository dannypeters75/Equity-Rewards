;; Equity-Based Profit Distribution Smart Contract
;;
;; A comprehensive blockchain-based system for automated profit sharing among equity holders.
;; Enables transparent, secure, and programmable distribution of profits based on predetermined
;; ownership percentages. Features include multi-round distribution cycles, stakeholder access
;; control, comprehensive claim tracking, and emergency management capabilities.
;;
;; Core Capabilities:
;; - Precision equity management using basis points (0.01% granularity)
;; - Automated profit distribution rounds with auditable history
;; - Stakeholder access control and blacklist management
;; - Transparent claim tracking and balance accumulation
;; - Emergency withdrawal and contract management functions
;; - Comprehensive validation and security protocols

(define-constant contract-owner tx-sender)

;; ERROR CONSTANTS - Access Control & Authorization

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-STAKEHOLDER-BLACKLISTED (err u101))
(define-constant ERR-INVALID-CALLER-PERMISSIONS (err u102))

;; ERROR CONSTANTS - Contract Initialization & State

(define-constant ERR-CONTRACT-ALREADY-INITIALIZED (err u200))
(define-constant ERR-CONTRACT-NOT-INITIALIZED (err u201))
(define-constant ERR-INVALID-CONTRACT-STATE (err u202))

;; ERROR CONSTANTS - Input Validation

(define-constant ERR-INVALID-PERCENTAGE-VALUE (err u300))
(define-constant ERR-INVALID-MINIMUM-STAKE-AMOUNT (err u301))
(define-constant ERR-INVALID-PRINCIPAL-ADDRESS (err u302))
(define-constant ERR-ZERO-AMOUNT-PROVIDED (err u303))
(define-constant ERR-INVALID-ROUND-IDENTIFIER (err u304))

;; ERROR CONSTANTS - Business Logic & Operations

(define-constant ERR-TOTAL-PERCENTAGE-EXCEEDED (err u400))
(define-constant ERR-STAKEHOLDER-NOT-REGISTERED (err u401))
(define-constant ERR-INSUFFICIENT-OWNERSHIP-STAKE (err u402))
(define-constant ERR-DISTRIBUTION-ROUND-ACTIVE (err u403))
(define-constant ERR-DISTRIBUTION-ROUND-INACTIVE (err u404))
(define-constant ERR-PROFITS-ALREADY-CLAIMED (err u405))
(define-constant ERR-STAKEHOLDER-ALREADY-EXISTS (err u406))

;; ERROR CONSTANTS - Financial Operations

(define-constant ERR-INSUFFICIENT-CONTRACT-BALANCE (err u500))
(define-constant ERR-TRANSFER-FAILED (err u501))
(define-constant ERR-INSUFFICIENT-USER-BALANCE (err u502))

;; SYSTEM CONFIGURATION CONSTANTS

(define-constant max-percentage-basis-points u10000) ;; 100.00% in basis points
(define-constant default-minimum-stake-threshold u1000000) ;; 1 STX in microSTX
(define-constant contract-address (as-contract tx-sender))

;; CONTRACT STATE VARIABLES

(define-data-var is-contract-initialized bool false)
(define-data-var total-contributions-received uint u0)
(define-data-var active-distribution-round bool false)
(define-data-var current-round-number uint u0)
(define-data-var total-lifetime-distributions uint u0)
(define-data-var minimum-stake-threshold uint default-minimum-stake-threshold)
(define-data-var total-allocated-percentage uint u0)

;; DATA STORAGE STRUCTURES

(define-map stakeholder-equity-records principal { 
  ownership-percentage-basis-points: uint 
})

(define-map stakeholder-balance-ledger principal uint)

(define-map distribution-round-history uint { 
  total-amount-distributed: uint, 
  round-completion-block: uint 
})

(define-map profit-claim-tracking { 
  round-id: uint, 
  stakeholder-principal: principal 
} bool)

(define-map stakeholder-access-control principal bool)

;; PUBLIC READ-ONLY FUNCTIONS - Stakeholder Information

(define-read-only (get-stakeholder-equity-info (stakeholder-address principal))
  (default-to { ownership-percentage-basis-points: u0 } 
    (map-get? stakeholder-equity-records stakeholder-address))
)

(define-read-only (get-stakeholder-balance (stakeholder-address principal))
  (default-to u0 (map-get? stakeholder-balance-ledger stakeholder-address))
)

(define-read-only (get-distribution-round-info (round-id uint))
  (map-get? distribution-round-history round-id)
)

(define-read-only (has-claimed-profits (round-id uint) (stakeholder-address principal))
  (default-to false 
    (map-get? profit-claim-tracking { 
      round-id: round-id, 
      stakeholder-principal: stakeholder-address 
    }))
)

(define-read-only (is-stakeholder-blacklisted (stakeholder-address principal))
  (default-to false (map-get? stakeholder-access-control stakeholder-address))
)

;; PUBLIC READ-ONLY FUNCTIONS - Contract Status

(define-read-only (is-contract-owner (caller-address principal))
  (is-eq caller-address contract-owner)
)

(define-read-only (get-contract-initialization-status)
  (var-get is-contract-initialized)
)

(define-read-only (is-distribution-round-active)
  (var-get active-distribution-round)
)

(define-read-only (get-current-round-number)
  (var-get current-round-number)
)

(define-read-only (get-total-allocated-percentage)
  (var-get total-allocated-percentage)
)

(define-read-only (get-available-contract-balance)
  (stx-get-balance contract-address)
)

;; PUBLIC READ-ONLY FUNCTIONS - Profit Calculations

(define-read-only (calculate-stakeholder-profit-share (round-id uint) (stakeholder-address principal))
  (let (
    (round-data (map-get? distribution-round-history round-id))
    (equity-data (get-stakeholder-equity-info stakeholder-address))
  )
    (if (and (is-some round-data) 
             (> (get ownership-percentage-basis-points equity-data) u0))
      (let (
        (round-details (unwrap-panic round-data))
        (ownership-percentage (get ownership-percentage-basis-points equity-data))
      )
        (if (has-claimed-profits round-id stakeholder-address)
          u0
          (/ (* (get total-amount-distributed round-details) ownership-percentage) 
             max-percentage-basis-points)
        )
      )
      u0
    )
  )
)

(define-read-only (get-comprehensive-contract-status)
  {
    contract-owner: contract-owner,
    initialization-status: (var-get is-contract-initialized),
    total-contributions: (var-get total-contributions-received),
    active-distribution-round: (var-get active-distribution-round),
    current-round-number: (var-get current-round-number),
    lifetime-distributions: (var-get total-lifetime-distributions),
    minimum-stake-threshold: (var-get minimum-stake-threshold),
    total-percentage-allocated: (var-get total-allocated-percentage),
    available-balance: (stx-get-balance contract-address)
  }
)

;; PRIVATE ACCESS CONTROL FUNCTIONS

(define-private (require-contract-owner)
  (if (is-eq tx-sender contract-owner)
    (ok true)
    (err ERR-UNAUTHORIZED-ACCESS)
  )
)

(define-private (require-contract-initialized)
  (if (var-get is-contract-initialized)
    (ok true)
    (err ERR-CONTRACT-NOT-INITIALIZED)
  )
)

(define-private (require-contract-not-initialized)
  (if (not (var-get is-contract-initialized))
    (ok true)
    (err ERR-CONTRACT-ALREADY-INITIALIZED)
  )
)

(define-private (require-stakeholder-not-blacklisted (user-address principal))
  (if (is-stakeholder-blacklisted user-address)
    (err ERR-STAKEHOLDER-BLACKLISTED)
    (ok true)
  )
)

(define-private (require-distribution-round-inactive)
  (if (not (var-get active-distribution-round))
    (ok true)
    (err ERR-DISTRIBUTION-ROUND-ACTIVE)
  )
)

(define-private (require-distribution-round-active)
  (if (var-get active-distribution-round)
    (ok true)
    (err ERR-DISTRIBUTION-ROUND-INACTIVE)
  )
)

;; CONTRACT INITIALIZATION FUNCTIONS

(define-public (initialize-contract (minimum-stake-amount uint))
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-not-initialized))
    (asserts! (> minimum-stake-amount u0) (err ERR-INVALID-MINIMUM-STAKE-AMOUNT))
    
    (var-set minimum-stake-threshold minimum-stake-amount)
    (var-set is-contract-initialized true)
    (ok true)
  )
)

;; STAKEHOLDER MANAGEMENT FUNCTIONS

(define-public (register-stakeholder (stakeholder-address principal) (ownership-percentage uint))
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (try! (require-distribution-round-inactive))
    (asserts! (and (not (is-eq stakeholder-address contract-owner))
                   (not (is-eq stakeholder-address contract-address))) 
              (err ERR-INVALID-PRINCIPAL-ADDRESS))
    (asserts! (<= ownership-percentage max-percentage-basis-points) 
              (err ERR-INVALID-PERCENTAGE-VALUE))
    
    (let (
      (current-total-percentage (var-get total-allocated-percentage))
      (new-total-percentage (+ current-total-percentage ownership-percentage))
    )
      (asserts! (<= new-total-percentage max-percentage-basis-points) 
        (err ERR-TOTAL-PERCENTAGE-EXCEEDED))
      
      (asserts! (is-eq (get ownership-percentage-basis-points 
                         (get-stakeholder-equity-info stakeholder-address)) u0)
        (err ERR-STAKEHOLDER-ALREADY-EXISTS))
      
      (map-set stakeholder-equity-records stakeholder-address { 
        ownership-percentage-basis-points: ownership-percentage 
      })
      (map-set stakeholder-balance-ledger stakeholder-address u0)
      (var-set total-allocated-percentage new-total-percentage)
      (ok true)
    )
  )
)

(define-public (update-stakeholder-ownership (stakeholder-address principal) (new-ownership-percentage uint))
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (try! (require-distribution-round-inactive))
    (asserts! (and (not (is-eq stakeholder-address contract-owner))
                   (not (is-eq stakeholder-address contract-address))) 
              (err ERR-INVALID-PRINCIPAL-ADDRESS))
    (asserts! (<= new-ownership-percentage max-percentage-basis-points) 
              (err ERR-INVALID-PERCENTAGE-VALUE))
    
    (let (
      (current-equity-data (get-stakeholder-equity-info stakeholder-address))
      (current-percentage (get ownership-percentage-basis-points current-equity-data))
    )
      (asserts! (> current-percentage u0) (err ERR-STAKEHOLDER-NOT-REGISTERED))
      
      (let (
        (adjusted-total-percentage (+ (- (var-get total-allocated-percentage) current-percentage) 
                                      new-ownership-percentage))
      )
        (asserts! (<= adjusted-total-percentage max-percentage-basis-points) 
          (err ERR-TOTAL-PERCENTAGE-EXCEEDED))
        
        (map-set stakeholder-equity-records stakeholder-address { 
          ownership-percentage-basis-points: new-ownership-percentage 
        })
        (var-set total-allocated-percentage adjusted-total-percentage)
        (ok true)
      )
    )
  )
)

(define-public (remove-stakeholder (stakeholder-address principal))
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (try! (require-distribution-round-inactive))
    (asserts! (and (not (is-eq stakeholder-address contract-owner))
                   (not (is-eq stakeholder-address contract-address))) 
              (err ERR-INVALID-PRINCIPAL-ADDRESS))
    
    (let (
      (current-equity-data (get-stakeholder-equity-info stakeholder-address))
      (current-percentage (get ownership-percentage-basis-points current-equity-data))
    )
      (asserts! (> current-percentage u0) (err ERR-STAKEHOLDER-NOT-REGISTERED))
      
      (map-delete stakeholder-equity-records stakeholder-address)
      (var-set total-allocated-percentage 
        (- (var-get total-allocated-percentage) current-percentage))
      (ok true)
    )
  )
)

;; ACCESS CONTROL MANAGEMENT FUNCTIONS

(define-public (blacklist-stakeholder (stakeholder-address principal))
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (asserts! (and (not (is-eq stakeholder-address contract-owner))
                   (not (is-eq stakeholder-address contract-address))) 
              (err ERR-INVALID-PRINCIPAL-ADDRESS))
    
    (map-set stakeholder-access-control stakeholder-address true)
    (ok true)
  )
)

(define-public (remove-stakeholder-from-blacklist (stakeholder-address principal))
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (asserts! (and (not (is-eq stakeholder-address contract-owner))
                   (not (is-eq stakeholder-address contract-address))) 
              (err ERR-INVALID-PRINCIPAL-ADDRESS))
    
    (map-set stakeholder-access-control stakeholder-address false)
    (ok true)
  )
)

;; DISTRIBUTION ROUND MANAGEMENT FUNCTIONS

(define-public (start-distribution-round)
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (try! (require-distribution-round-inactive))
    
    (var-set active-distribution-round true)
    (ok true)
  )
)

(define-public (end-distribution-round)
  (begin
    (try! (require-contract-owner))
    (try! (require-contract-initialized))
    (try! (require-distribution-round-active))
    
    (var-set active-distribution-round false)
    (ok true)
  )
)

;; CONTRIBUTION FUNCTIONS

(define-public (contribute-all-stx)
  (let (
    (contributor-balance (stx-get-balance tx-sender))
  )
    (begin
      (try! (require-contract-initialized))
      (try! (require-distribution-round-active))
      (asserts! (> contributor-balance u0) (err ERR-ZERO-AMOUNT-PROVIDED))
      
      (match (stx-transfer? contributor-balance tx-sender contract-address)
        success (begin
          (var-set total-contributions-received 
            (+ (var-get total-contributions-received) contributor-balance))
          (ok contributor-balance)
        )
        error (err ERR-TRANSFER-FAILED)
      )
    )
  )
)

(define-public (contribute-stx-amount (contribution-amount uint))
  (begin
    (try! (require-contract-initialized))
    (try! (require-distribution-round-active))
    (asserts! (> contribution-amount u0) (err ERR-ZERO-AMOUNT-PROVIDED))
    
    (match (stx-transfer? contribution-amount tx-sender contract-address)
      success (begin
        (var-set total-contributions-received 
          (+ (var-get total-contributions-received) contribution-amount))
        (ok contribution-amount)
      )
      error (err ERR-TRANSFER-FAILED)
    )
  )
)

;; PROFIT DISTRIBUTION FUNCTIONS

(define-public (execute-profit-distribution)
  (let (
    (contract-balance (stx-get-balance contract-address))
    (next-round-id (+ (var-get current-round-number) u1))
  )
    (begin
      (try! (require-contract-owner))
      (try! (require-contract-initialized))
      (try! (require-distribution-round-active))
      (asserts! (> contract-balance u0) (err ERR-ZERO-AMOUNT-PROVIDED))
      
      (map-set distribution-round-history next-round-id { 
        total-amount-distributed: contract-balance, 
        round-completion-block: block-height 
      })
      
      (var-set current-round-number next-round-id)
      (var-set total-lifetime-distributions 
        (+ (var-get total-lifetime-distributions) contract-balance))
      (var-set total-contributions-received u0)
      (var-set active-distribution-round false)
      
      (ok next-round-id)
    )
  )
)

(define-public (claim-profits (target-round-id uint))
  (let (
    (round-data (map-get? distribution-round-history target-round-id))
    (claimant-equity-data (get-stakeholder-equity-info tx-sender))
    (has-already-claimed (has-claimed-profits target-round-id tx-sender))
  )
    (begin
      (try! (require-contract-initialized))
      (try! (require-stakeholder-not-blacklisted tx-sender))
      
      (asserts! (is-some round-data) (err ERR-INVALID-ROUND-IDENTIFIER))
      (asserts! (not has-already-claimed) (err ERR-PROFITS-ALREADY-CLAIMED))
      (asserts! (> (get ownership-percentage-basis-points claimant-equity-data) u0) 
        (err ERR-INSUFFICIENT-OWNERSHIP-STAKE))
      
      (let (
        (round-details (unwrap-panic round-data))
        (ownership-percentage (get ownership-percentage-basis-points claimant-equity-data))
        (profit-amount (/ (* (get total-amount-distributed round-details) ownership-percentage) 
                         max-percentage-basis-points))
      )
        (map-set profit-claim-tracking { 
          round-id: target-round-id, 
          stakeholder-principal: tx-sender 
        } true)
        
        (map-set stakeholder-balance-ledger tx-sender 
          (+ (get-stakeholder-balance tx-sender) profit-amount))
        
        (match (as-contract (stx-transfer? profit-amount tx-sender tx-sender))
          success (ok profit-amount)
          error (err ERR-TRANSFER-FAILED)
        )
      )
    )
  )
)

;; EMERGENCY MANAGEMENT FUNCTIONS

(define-public (emergency-withdraw-all-funds)
  (let (
    (contract-balance (stx-get-balance contract-address))
  )
    (begin
      (try! (require-contract-owner))
      (asserts! (> contract-balance u0) (err ERR-ZERO-AMOUNT-PROVIDED))
      
      (match (as-contract (stx-transfer? contract-balance tx-sender contract-owner))
        success (ok contract-balance)
        error (err ERR-TRANSFER-FAILED)
      )
    )
  )
)