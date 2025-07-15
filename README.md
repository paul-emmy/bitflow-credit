# BitFlow Credit - Intelligent Lending Protocol

## Overview

BitFlow Credit is a revolutionary decentralized lending protocol that transforms borrowing behavior into digital reputation. The platform enables progressive loan access with reduced collateral requirements through proven payment history, creating a sustainable lending ecosystem that bridges traditional credit concepts with blockchain innovation.

## Key Features

- **Adaptive Credit Scoring**: Dynamic credit scoring mechanism that rewards responsible borrowers
- **Progressive Loan Access**: Users unlock superior loan terms through consistent repayment performance
- **Reduced Collateral Requirements**: Higher credit scores enable lower collateral ratios
- **Interest Rate Optimization**: Credit scores directly influence interest rates
- **Risk Management**: Dynamic scoring algorithms and collateral optimization strategies

## System Overview

The BitFlow Credit protocol operates on a credit-based lending model where users build reputation through successful loan repayments. The system maintains three core components:

1. **Credit Scoring Engine**: Tracks user creditworthiness and adjusts scores based on repayment behavior
2. **Loan Management System**: Handles loan creation, repayment, and lifecycle management
3. **Risk Assessment Module**: Calculates dynamic collateral requirements and interest rates

## Contract Architecture

### Core Data Structures

#### UserScores Map

Stores comprehensive credit profiles for each user:

- `score`: Current credit score (50-100 range)
- `total-borrowed`: Cumulative amount borrowed
- `total-repaid`: Cumulative amount successfully repaid
- `loans-taken`: Total number of loans initiated
- `loans-repaid`: Total number of loans successfully completed
- `last-update`: Block height of last profile update

#### Loans Map

Maintains detailed loan records:

- `borrower`: Principal address of the borrower
- `amount`: Loan principal amount
- `collateral`: Collateral amount locked
- `due-height`: Block height when loan becomes due
- `interest-rate`: Applied interest rate
- `is-active`: Current loan status
- `is-defaulted`: Default status indicator
- `repaid-amount`: Amount repaid to date

#### UserLoans Map

Tracks active loans per user (maximum 20 loans):

- `active-loans`: List of active loan IDs for the user

### Core Functions

#### Public Functions

**`initialize-score()`**

- Creates initial credit profile for new users
- Sets starting credit score to minimum (50)
- Initializes all metrics to zero

**`request-loan(amount, collateral, duration)`**

- Validates borrower eligibility (minimum score: 70)
- Calculates dynamic collateral requirements based on credit score
- Processes collateral transfer and loan disbursement
- Updates user loan registry

**`repay-loan(loan-id, amount)`**

- Processes partial or full loan repayments
- Automatically releases collateral upon full repayment
- Updates credit score based on repayment behavior
- Handles loan completion and status updates

#### Administrative Functions

**`mark-loan-defaulted(loan-id)`**

- Owner-only function to mark overdue loans as defaulted
- Applies credit score penalties
- Updates loan status to inactive and defaulted

### Credit Scoring Algorithm

The protocol implements a sophisticated credit scoring system:

#### Score Calculation

- **Range**: 50 (minimum) to 100 (maximum)
- **Starting Score**: 50 for new users
- **Improvement**: +2 points per successful loan repayment
- **Penalty**: -10 points for loan defaults

#### Dynamic Collateral Requirements

```
collateral_ratio = 100 - (score * 50 / 100)
required_collateral = (loan_amount * collateral_ratio) / 100
```

#### Adaptive Interest Rates

```
base_rate = 10%
interest_rate = base_rate - (score * 5 / 100)
```

## Data Flow

### Loan Request Flow

1. User calls `request-loan()` with desired amount, collateral, and duration
2. System validates user credit score (minimum 70 required)
3. Protocol calculates required collateral based on credit score
4. User transfers collateral to contract
5. Contract creates loan record and disburses funds
6. User loan registry updated with new loan ID

### Repayment Flow

1. User calls `repay-loan()` with loan ID and repayment amount
2. System validates loan exists and is active
3. User transfers repayment amount to contract
4. Contract updates loan repayment status
5. For full repayment:
   - Credit score increased by 2 points
   - Collateral released to user
   - Loan marked as inactive
6. Loan registry updated with new status

### Default Handling Flow

1. Admin identifies overdue loan (past due height)
2. Admin calls `mark-loan-defaulted()` for specific loan
3. System applies 10-point credit score penalty
4. Loan marked as defaulted and inactive
5. Collateral retained by protocol

## Technical Specifications

### Constants

- `MIN-SCORE`: 50 (minimum credit score)
- `MAX-SCORE`: 100 (maximum credit score)
- `MIN-LOAN-SCORE`: 70 (minimum score required for loans)

### Limits

- Maximum active loans per user: 5
- Maximum loan duration: 52,560 blocks (~1 year)
- Maximum tracked loans per user: 20

### Error Codes

- `ERR-UNAUTHORIZED` (u1): Unauthorized access
- `ERR-INSUFFICIENT-BALANCE` (u2): Insufficient balance
- `ERR-INVALID-AMOUNT` (u3): Invalid amount specified
- `ERR-LOAN-NOT-FOUND` (u4): Loan not found
- `ERR-LOAN-DEFAULTED` (u5): Loan has been defaulted
- `ERR-INSUFFICIENT-SCORE` (u6): Credit score too low
- `ERR-ACTIVE-LOAN` (u7): Too many active loans
- `ERR-NOT-DUE` (u8): Loan not yet due
- `ERR-INVALID-DURATION` (u9): Invalid loan duration
- `ERR-INVALID-LOAN-ID` (u10): Invalid loan identifier

## Query Functions

### Read-Only Functions

- `get-user-score(user)`: Retrieve user credit profile
- `get-loan(loan-id)`: Retrieve specific loan details
- `get-user-active-loans(user)`: Retrieve user's active loans

## Security Features

- **Access Control**: Admin-only functions for default management
- **Validation**: Comprehensive input validation for all operations
- **State Management**: Consistent state updates across all operations
- **Collateral Protection**: Automatic collateral management and release

## Getting Started

1. **Initialize Profile**: New users must call `initialize-score()` to create their credit profile
2. **Build Credit**: Start with smaller loans to build repayment history
3. **Progressive Access**: Higher credit scores unlock better loan terms
4. **Maintain Score**: Consistent repayments improve credit standing

## Future Enhancements

- Multi-asset collateral support
- Compound interest calculations
- Credit score decay mechanisms
- Loan refinancing options
- Governance token integration

## License

This project is licensed under the MIT License.
