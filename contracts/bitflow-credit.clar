;; Title: BitFlow Credit - Intelligent Lending Protocol
;;
;; Summary: 
;; Revolutionary credit-scoring lending platform that transforms borrowing
;; behavior into digital reputation, enabling progressive loan access with
;; reduced collateral requirements through proven payment history.
;;
;; Description:
;; BitFlow Credit introduces a paradigm shift in decentralized finance by
;; implementing an adaptive credit scoring mechanism that rewards responsible
;; borrowers with enhanced lending privileges. The protocol intelligently
;; adjusts collateral requirements and interest rates based on demonstrated
;; repayment behavior, creating a sustainable lending ecosystem that bridges
;; traditional credit concepts with blockchain innovation. Users progressively
;; unlock superior loan terms through consistent repayment performance, while
;; the protocol maintains risk management through dynamic scoring algorithms
;; and collateral optimization strategies.

;; CONTRACT CONFIGURATION

(define-constant CONTRACT-OWNER tx-sender)

;; Error Constants
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-LOAN-NOT-FOUND (err u4))
(define-constant ERR-LOAN-DEFAULTED (err u5))
(define-constant ERR-INSUFFICIENT-SCORE (err u6))
(define-constant ERR-ACTIVE-LOAN (err u7))
(define-constant ERR-NOT-DUE (err u8))
(define-constant ERR-INVALID-DURATION (err u9))
(define-constant ERR-INVALID-LOAN-ID (err u10))

;; Credit Scoring Parameters
(define-constant MIN-SCORE u50)
(define-constant MAX-SCORE u100)
(define-constant MIN-LOAN-SCORE u70)

;; DATA STRUCTURES

;; User Credit Profile Storage
(define-map UserScores
  { user: principal }
  {
    score: uint,
    total-borrowed: uint,
    total-repaid: uint,
    loans-taken: uint,
    loans-repaid: uint,
    last-update: uint,
  }
)

;; Loan Registry
(define-map Loans
  { loan-id: uint }
  {
    borrower: principal,
    amount: uint,
    collateral: uint,
    due-height: uint,
    interest-rate: uint,
    is-active: bool,
    is-defaulted: bool,
    repaid-amount: uint,
  }
)

;; User Active Loans Tracking
(define-map UserLoans
  { user: principal }
  { active-loans: (list 20 uint) }
)

;; STATE VARIABLES

(define-data-var next-loan-id uint u0)
(define-data-var total-stx-locked uint u0)

;; CORE PUBLIC FUNCTIONS

;; Initialize Credit Profile
;; Creates a new credit profile for first-time users
(define-public (initialize-score)
  (let ((sender tx-sender))
    (asserts! (is-none (map-get? UserScores { user: sender })) ERR-UNAUTHORIZED)
    (ok (map-set UserScores { user: sender } {
      score: MIN-SCORE,
      total-borrowed: u0,
      total-repaid: u0,
      loans-taken: u0,
      loans-repaid: u0,
      last-update: stacks-block-height,
    }))
  )
)

;; Request Loan
;; Creates a new collateralized loan with dynamic terms based on credit score
(define-public (request-loan
    (amount uint)
    (collateral uint)
    (duration uint)
  )
  (let (
      (sender tx-sender)
      (loan-id (+ (var-get next-loan-id) u1))
      (user-score (unwrap! (map-get? UserScores { user: sender }) ERR-UNAUTHORIZED))
      (active-loans (default-to { active-loans: (list) } (map-get? UserLoans { user: sender })))
    )
    ;; Validate Loan Request
    (asserts! (>= (get score user-score) MIN-LOAN-SCORE) ERR-INSUFFICIENT-SCORE)
    (asserts! (<= (len (get active-loans active-loans)) u5) ERR-ACTIVE-LOAN)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (and (> duration u0) (<= duration u52560)) ERR-INVALID-DURATION)
    ;; Max ~1 year
    ;; Calculate Dynamic Collateral Requirements
    (let ((required-collateral (calculate-required-collateral amount (get score user-score))))
      (asserts! (>= collateral required-collateral) ERR-INSUFFICIENT-BALANCE)
      ;; Process Collateral Transfer
      (try! (stx-transfer? collateral sender (as-contract tx-sender)))
      ;; Create Loan Record
      (map-set Loans { loan-id: loan-id } {
        borrower: sender,
        amount: amount,
        collateral: collateral,
        due-height: (+ stacks-block-height duration),
        interest-rate: (calculate-interest-rate (get score user-score)),
        is-active: true,
        is-defaulted: false,
        repaid-amount: u0,
      })
      ;; Update User Loan Registry
      (try! (update-user-loans sender loan-id))
      ;; Disburse Loan Amount
      (as-contract (try! (stx-transfer? amount tx-sender sender)))
      ;; Update Global State
      (var-set next-loan-id loan-id)
      (var-set total-stx-locked (+ (var-get total-stx-locked) collateral))
      (ok loan-id)
    )
  )
)

;; Process Loan Repayment
;; Handles partial or full loan repayments with automatic collateral release
(define-public (repay-loan
    (loan-id uint)
    (amount uint)
  )
  (let (
      (sender tx-sender)
      (loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
    )
    ;; Validate Repayment Request
    (asserts! (is-eq sender (get borrower loan)) ERR-UNAUTHORIZED)
    (asserts! (get is-active loan) ERR-LOAN-NOT-FOUND)
    (asserts! (not (get is-defaulted loan)) ERR-LOAN-DEFAULTED)
    (asserts! (<= loan-id (var-get next-loan-id)) ERR-INVALID-LOAN-ID)
    ;; Calculate Total Amount Due
    (let ((total-due (calculate-total-due loan)))
      (asserts! (>= amount u0) ERR-INVALID-AMOUNT)
      ;; Process Repayment Transfer
      (try! (stx-transfer? amount sender (as-contract tx-sender)))
      ;; Update Loan Status
      (let ((new-repaid-amount (+ (get repaid-amount loan) amount)))
        (map-set Loans { loan-id: loan-id }
          (merge loan {
            repaid-amount: new-repaid-amount,
            is-active: (< new-repaid-amount total-due),
          })
        )
        ;; Handle Full Repayment
        (if (>= new-repaid-amount total-due)
          (begin
            (try! (update-credit-score sender true loan))
            (as-contract (try! (stx-transfer? (get collateral loan) tx-sender sender)))
            (var-set total-stx-locked
              (- (var-get total-stx-locked) (get collateral loan))
            )
          )
          true
        )
        (ok true)
      )
    )
  )
)

;; COMPUTATION FUNCTIONS

;; Calculate Dynamic Collateral Requirements
;; Higher credit scores require reduced collateral ratios
(define-private (calculate-required-collateral
    (amount uint)
    (score uint)
  )
  (let ((collateral-ratio (- u100 (/ (* score u50) u100))))
    (/ (* amount collateral-ratio) u100)
  )
)

;; Calculate Adaptive Interest Rates
;; Superior credit scores unlock preferential interest rates
(define-private (calculate-interest-rate (score uint))
  (let ((base-rate u10))
    (- base-rate (/ (* score u5) u100))
  )
)

;; Calculate Total Loan Obligation
;; Computes principal plus accrued interest
(define-private (calculate-total-due (loan {
  borrower: principal,
  amount: uint,
  collateral: uint,
  due-height: uint,
  interest-rate: uint,
  is-active: bool,
  is-defaulted: bool,
  repaid-amount: uint,
}))
  (let ((interest (* (get amount loan) (get interest-rate loan))))
    (+ (get amount loan) (/ interest u100))
  )
)

;; Update Credit Score Algorithm
;; Adjusts user creditworthiness based on repayment behavior
(define-private (update-credit-score
    (user principal)
    (success bool)
    (loan {
      borrower: principal,
      amount: uint,
      collateral: uint,
      due-height: uint,
      interest-rate: uint,
      is-active: bool,
      is-defaulted: bool,
      repaid-amount: uint,
    })
  )
  (let (
      (current-score (unwrap! (map-get? UserScores { user: user }) ERR-UNAUTHORIZED))
      (new-score (if success
        (if (<= (+ (get score current-score) u2) MAX-SCORE)
          (+ (get score current-score) u2)
          MAX-SCORE
        )
        (if (>= (- (get score current-score) u10) MIN-SCORE)
          (- (get score current-score) u10)
          MIN-SCORE
        )
      ))
    )
    ;; Update Score Based on Performance
    (if success
      (map-set UserScores { user: user }
        (merge current-score {
          score: new-score,
          total-repaid: (+ (get total-repaid current-score) (get amount loan)),
          loans-repaid: (+ (get loans-repaid current-score) u1),
          last-update: stacks-block-height,
        })
      )
      (map-set UserScores { user: user }
        (merge current-score {
          score: new-score,
          last-update: stacks-block-height,
        })
      )
    )
    (ok true)
  )
)