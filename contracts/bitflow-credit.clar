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