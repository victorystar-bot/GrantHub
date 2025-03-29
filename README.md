# GrantHub: Decentralized Grant Distribution Platform

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [Architecture](#architecture)
- [Smart Contract Details](#smart-contract-details)
  - [Data Structures](#data-structures)
  - [Key Functions](#key-functions)
  - [Error Handling](#error-handling)
  - [Security Measures](#security-measures)
- [User Roles](#user-roles)
- [Workflow](#workflow)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Deployment](#deployment)
- [Usage Examples](#usage-examples)
  - [For Pool Administrators](#for-pool-administrators)
  - [For Grant Applicants](#for-grant-applicants)
  - [For Voters](#for-voters)
- [Testing](#testing)
- [Performance Considerations](#performance-considerations)
- [Governance Model](#governance-model)
- [Use Cases](#use-cases)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [Acknowledgments](#acknowledgments)

## Overview

GrantHub is a comprehensive, transparent, and decentralized solution for managing grant distribution processes on the Stacks blockchain. By leveraging blockchain technology, GrantHub ensures immutable record-keeping, democratic decision-making, and phase-based fund distribution for organizations of all sizes.

**Current Version:** 1.0.0  
**Blockchain:** Stacks  
**Contract Language:** Clarity  

## Problem Statement

Traditional grant distribution systems face several challenges:

1. **Lack of Transparency:** Limited visibility into decision-making processes and fund allocations
2. **Centralized Control:** Decisions often made by small committees without broader community input
3. **Inefficient Fund Distribution:** All-or-nothing funding models that don't align with project progress
4. **High Administrative Overhead:** Manual tracking of applications, reviews, and disbursements
5. **Trust Issues:** Recipients and funders struggle with mutual accountability
6. **Limited Accessibility:** High barriers to entry for smaller organizations or individuals

## Solution

GrantHub addresses these challenges through a blockchain-based platform that provides:

- **Full Transparency:** All funding decisions, votes, and milestone completions are recorded on-chain and publicly verifiable
- **Decentralized Governance:** Customizable voting mechanisms allow broad community participation in funding decisions
- **Phase-Based Funding:** Funds are released incrementally as recipients complete predefined objectives, ensuring accountability
- **Automated Workflows:** Smart contract automation reduces administrative burden and human error
- **Trustless Interactions:** Cryptographic verification replaces trust requirements between parties
- **Inclusivity:** Low barriers to entry for both funders and applicants regardless of size or background

## Architecture

GrantHub uses a modular architecture consisting of:

1. **Core Smart Contract:** The primary Clarity contract deployed on Stacks blockchain
2. **SIP-010 Token Integration:** Compatibility with any fungible token following the SIP-010 standard
3. **Frontend Interface:** (Optional) Web application for interacting with the contract
4. **Analytics Layer:** (Optional) Data aggregation for visualizing platform activity

```
┌───────────────────┐     ┌───────────────────┐
│                   │     │                   │
│  Frontend UI      │────▶│  Analytics Layer  │
│                   │     │                   │
└─────────┬─────────┘     └───────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│                                     │
│  GrantHub Smart Contract (Clarity)  │
│                                     │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│                                     │
│  SIP-010 Compatible Token Contract  │
│                                     │
└─────────────────────────────────────┘
```

## Smart Contract Details

### Data Structures

GrantHub uses the following primary data structures:

1. **Funding Pools**
   ```clarity
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
   ```

2. **Applications**
   ```clarity
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
   ```

3. **Votes and Vote Tallies**
   ```clarity
   (define-map votes
       { application-id: uint, voter: principal }
       { in-favor: bool }
   )

   (define-map vote-tallies
       { application-id: uint }
       {
           positive-count: uint,
           total-count: uint
       }
   )
   ```

### Key Functions

#### Pool Management
- `create-funding-pool`: Create a new funding pool with specified budget and token
- `deactivate-funding-pool`: (Planned) Deactivate a pool and reclaim unallocated funds

#### Application Processing
- `submit-application`: Submit a new funding request with phase details
- `update-application`: (Planned) Modify an application before it's reviewed
- `withdraw-application`: (Planned) Remove an application from consideration

#### Voting System
- `vote-on-application`: Cast a vote for or against an application
- `get-vote-counts`: View current voting statistics for an application
- `has-voted`: (Planned) Check if a principal has already voted

#### Approval and Fund Distribution
- `finalize-application`: Process application based on voting results
- `complete-phase`: Mark a project phase as completed
- `verify-phase-completion`: (Planned) Allow reviewers to verify phase completion
- `distribute-funds`: (Planned) Automatically transfer funds upon phase completion

#### Administration
- `update-minimum-votes`: (Planned) Change the minimum vote threshold
- `update-quorum-threshold`: (Planned) Modify the percentage needed for approval

### Error Handling

The contract includes comprehensive error handling with descriptive error codes:

| Error Code | Description | Trigger Condition |
|------------|-------------|-------------------|
| u100 | Owner Only | Non-owner attempts privileged action |
| u101 | Not Found | Referenced ID doesn't exist |
| u102 | Unauthorized | User lacks permissions for action |
| u103 | Invalid State | Action not allowed in current state |
| u104 | Insufficient Funds | Requested amount exceeds available funds |
| u105 | Invalid Amount | Amount violates min/max constraints |
| u106 | Invalid Token | Token contract doesn't comply with SIP-010 |
| u107 | Invalid Phase | Phase parameters are incorrect |
| u108 | Insufficient Votes | Voting doesn't meet minimum threshold |
| u109 | No Votes | Attempt to finalize with zero votes |

### Security Measures

GrantHub implements several security measures:

1. **Principal-Based Authorization:** Functions verify caller identity before execution
2. **Validation Checks:** All inputs undergo rigorous validation before processing
3. **Phase-Based Fund Release:** Funds are never released all at once
4. **Immutable Record-Keeping:** All actions are recorded on-chain
5. **Quorum Requirements:** Minimum participation needed for decision validity

## User Roles

GrantHub supports multiple user roles with distinct permissions:

### Pool Administrators
- Create and manage funding pools
- Configure pool parameters
- Finalize application decisions
- Verify phase completions (optional)

### Grant Applicants
- Submit funding applications
- Provide detailed phase breakdowns
- Report phase completions
- Receive funds upon verification

### Community Voters
- Review applications
- Cast votes for or against funding
- Monitor funded project progress
- Participate in governance decisions

## Workflow

The standard GrantHub workflow follows these steps:

1. **Pool Creation:** Administrator initializes funding pool with budget and parameters
2. **Application Submission:** Applicants submit detailed funding requests with phases
3. **Community Review:** Voters assess applications and cast their votes
4. **Decision Finalization:** After voting period, administrator finalizes decisions
5. **Project Execution:** Approved applicants begin work on their first phase
6. **Phase Completion:** As phases are completed, applicants mark them as such
7. **Fund Distribution:** Funds are released for completed phases
8. **Project Completion:** Process repeats until all phases are completed

```
┌──────────────┐     ┌─────────────────┐     ┌───────────────┐     ┌────────────────┐
│              │     │                 │     │               │     │                │
│ Pool Creation│────▶│  Application    │────▶│ Voting Period │────▶│ Finalization   │
│              │     │  Submission     │     │               │     │                │
└──────────────┘     └─────────────────┘     └───────────────┘     └────────┬───────┘
                                                                            │
                                                                            ▼
┌──────────────┐     ┌─────────────────┐     ┌───────────────┐     ┌────────────────┐
│              │     │                 │     │               │     │                │
│  Completion  │◀────│ Fund Release    │◀────│Phase Reporting│◀────│ Project Start  │
│              │     │                 │     │               │     │                │
└──────────────┘     └─────────────────┘     └───────────────┘     └────────────────┘
```

## Getting Started

### Prerequisites

- Stacks blockchain node (for local testing)
- Clarity CLI tools

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/victorystar-bot/granthub.git
   cd granthub
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Prepare the environment:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

### Configuration

GrantHub can be configured through the following parameters:

| Parameter | Description | Default Value | Adjustable Post-Deployment |
|-----------|-------------|---------------|----------------------------|
| `minimum-funding-amount` | Smallest allowed request | u1000000 | Yes |
| `maximum-funding-amount` | Largest allowed request | u1000000000 | Yes |
| `minimum-votes-required` | Votes needed for decision | u3 | Yes |
| `quorum-threshold` | Percentage needed for approval | u50 | Yes |
| `contract-owner` | Administrator address | Deployer | No |

### Deployment

1. Deploy to Stacks testnet:
   ```bash
   npm run deploy:testnet
   ```

2. Deploy to Stacks mainnet:
   ```bash
   npm run deploy:mainnet
   ```

3. Verify contract:
   ```bash
   npm run verify -- [contract-id]
   ```

## Usage Examples

### For Pool Administrators

**Creating a New Funding Pool:**

```clarity
;; Deploy a pool with 1,000,000 tokens
(contract-call? .granthub create-funding-pool u1000000 .my-token)
```

**Finalizing an Application:**

```clarity
;; After voting period ends, finalize the application
(contract-call? .granthub finalize-application u1)
```

**Checking Pool Status:**

```clarity
;; Read-only function to check pool status
(contract-call? .granthub get-pool-info u1)
```

### For Grant Applicants

**Submitting a New Application:**

```clarity
;; Request 500,000 tokens across 3 phases
(contract-call? .granthub submit-application u1 u500000 
  (list 
    {description: "Phase 1: Research & Planning", amount: u100000, completed: false}
    {description: "Phase 2: Development & Testing", amount: u300000, completed: false}
    {description: "Phase 3: Deployment & Marketing", amount: u100000, completed: false}
  )
)
```

**Reporting Phase Completion:**

```clarity
;; Mark the first phase (index 0) as complete
(contract-call? .granthub complete-phase u1 u0)
```

**Checking Application Status:**

```clarity
;; Get current application status
(contract-call? .granthub get-application-info u1)
```

### For Voters

**Casting a Vote:**

```clarity
;; Vote in favor of an application
(contract-call? .granthub vote-on-application u1 true)

;; Vote against an application
(contract-call? .granthub vote-on-application u1 false)
```

**Checking Voting Results:**

```clarity
;; Get current vote counts
(contract-call? .granthub get-vote-counts u1)
```

## Testing

GrantHub includes comprehensive tests to ensure reliability:

1. Run unit tests:
   ```bash
   npm run test:unit
   ```

2. Run integration tests:
   ```bash
   npm run test:integration
   ```

3. Run security audit:
   ```bash
   npm run test:security
   ```

## Performance Considerations

When using GrantHub, consider the following performance aspects:

1. **Gas Costs:** Complex operations like application finalization require more gas
2. **Storage Limitations:** Each application with phases consumes blockchain storage
3. **Voting Scale:** The system is optimized for dozens to hundreds of voters per application
4. **Phase Management:** Limit phases to 5 or fewer for optimal performance
5. **Batching:** Consider batching operations when possible to reduce transaction costs

## Governance Model

GrantHub supports flexible governance models:

1. **Administrator-led:** Pool owner retains final decision authority
2. **Community-driven:** Decisions solely based on community votes
3. **Hybrid approach:** Community votes with administrator oversight
4. **Multi-sig:** (Planned) Multiple administrators required for crucial decisions


## Use Cases

GrantHub is suitable for various funding scenarios:

### DAO Treasury Management
Decentralized autonomous organizations can use GrantHub to transparently allocate treasury funds to projects.

### Hackathon Prize Distribution
Distribute prizes to winning teams based on milestone delivery rather than up-front.

### Community Grants Programs
Open-source communities can run governance-driven grant programs with transparent voting.

### Corporate Innovation Funds
Companies can manage innovation grants with accountable phase-based releases.

### Collaborative Research Funding
Research organizations can pool resources and collectively decide on funding allocations.

## Future Enhancements

The GrantHub roadmap includes:

### Short-term (3-6 months)
- Multi-signature approval for phase verification
- Update mechanisms for existing applications
- Withdrawal functionality for administrators and applicants
- Enhanced event emission for off-chain tracking

### Medium-term (6-12 months)
- Token staking for weighted voting rights
- Integration with established governance DAOs
- Enhanced analytics and reporting
- Customizable voting periods

### Long-term (12+ months)
- Cross-chain compatibility
- AI-assisted application assessment
- Reputation system for applicants
- Advanced voting mechanisms (quadratic, conviction)

## Contributing

We welcome contributions to GrantHub! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

