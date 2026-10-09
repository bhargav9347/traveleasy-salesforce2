# TravelEasy — Intelligent Travel & Spend Control Platform

**2027 Nurture Partner Network (NPN) Salesforce Developer Catalyst Hackathon**

---

## Executive Summary & Business Vision

**TravelEasy** is an enterprise-grade **Intelligent Travel & Spend Control Platform** built natively on Salesforce DX. Designed to replace legacy spreadsheet-driven travel and expense workflows, TravelEasy unifies employee travel planning, policy validation, exception detection, automated approvals, and financial reimbursement into an end-to-end intelligent journey.

### Primary Innovation: Smart Expense Control Engine
Rather than relying on opaque AI or manual finance inspection, TravelEasy introduces a **deterministic, explainable policy rule engine**:
- **Automates Normal Cases**: Compliant expenses are validated instantly and auto-queued for reimbursement via Queueable Apex.
- **Escalates Policy Exceptions**: Violations (category limits, missing receipts, potential duplicates, budget overruns) generate auditable `Expense_Exception__c` records for human review.
- **Explainable Results**: Every expense item receives an explicit status badge (`PASS`, `POLICY_EXCEPTION`, `MISSING_RECEIPT`, `POTENTIAL_DUPLICATE`, `BUDGET_OVERRUN`, `HUMAN_REVIEW_REQUIRED`).

---

## Architectural Framework & Core Components

```
User Layer (Employee / Manager / Finance / Admin)
        ↓
Lightning Experience & Trip Wallet LWC
        ↓
TravelEasy Application & Navigation Tabs
        ↓
Salesforce Core Objects (Travel Request, Expense Report, Expense Item, Expense Exception, Reimbursement, Integration Log)
        ↓
Validation Rules & Formula Fields
        ↓
Smart Expense Control Engine (Apex Trigger Handler & Service Classes)
        ↓
Configurable Policy Engine (Travel_Policy_Rule__mdt Custom Metadata)
        ↓
Async Processing (Queueable Reimbursement, Batch Reconciliation, SLA Monitor)
        ↓
Audit & Integration Logging (Corporate Finance ERP Mock / Integration Log)
```

---

## Data Model & Custom Objects

1. **Travel Request (`Travel_Request__c`)**: Core trip record storing destination, dates, estimated budget, department, travel type, duration, budget variance, and approval status.
2. **Expense Report (`Expense_Report__c`)**: Summarizes submitted expenses for a trip with roll-up summary totals, exception flags, and reimbursement status.
3. **Expense Item (`Expense_Item__c`)**: Individual expense record storing category, vendor, amount, reimbursable amount, receipt status, and policy result.
4. **Expense Exception (`Expense_Exception__c`)**: Auditable exception record capturing rule violations, severity, reviewer notes, and resolution status.
5. **Reimbursement (`Reimbursement__c`)**: Tracks financial payout, payment reference, processing dates, and completion status.
6. **Integration Log (`Integration_Log__c`)**: Logs API payloads, endpoints, status codes, and error traces.
7. **Travel Policy Rule (`Travel_Policy_Rule__mdt`)**: Custom metadata type driving configurable category limits, receipt thresholds, and active rule toggles.

---

## Key Features Implemented

- **Configurable Policy Engine**: Category limits (Meals ₹2,000, Flights ₹15,000, Lodging ₹8,000, Transport ₹3,000) configured via Custom Metadata Types.
- **Duplicate & Variance Detection**: Identifies potential duplicate submissions within ±3 days and flags budget overruns against estimated trip costs.
- **Trip Wallet LWC**: Real-time Lightning Web Component displaying budget utilization progress bars, remaining balance, and expense item validation badges.
- **Asynchronous Reimbursement**: Queueable Apex (`ReimbursementQueueable`) generates payment references and logs ERP integration records.
- **Batch & Scheduled Automation**: Batch Apex (`ExpenseReconciliationBatch`) and Scheduled SLA Monitor (`PendingApprovalSLAMonitor`).
- **Security & Access Control**: Complete Permission Set (`TravelEasy_Admin`) with Object and Field-Level Security (FLS).

---

## Test Execution & Verification

All Apex classes, triggers, batch jobs, queueables, and controllers are verified with 100% test pass rate across 66 unit tests.

### Running Unit Tests
```bash
sf apex run test --code-coverage --result-format human
```

### End-to-End Verification
Run the anonymous Apex script located in `scratch/e2e_test_script.apex` to execute end-to-end normal and exception workflows:
```bash
sf apex run --file scratch/e2e_test_script.apex
```

---

## Repository Structure & Source Format

- `force-app/main/default/objects/`: Custom Object & Field Definitions
- `force-app/main/default/classes/`: Apex Controllers, Services, Triggers Handlers, Batch, Queueables & Unit Tests
- `force-app/main/default/triggers/`: Apex Triggers
- `force-app/main/default/customMetadata/`: Policy Rule Configuration Records
- `force-app/main/default/lwc/tripWallet/`: Trip Wallet LWC Component
- `force-app/main/default/permissionsets/`: TravelEasy Admin Permission Set
- `force-app/main/default/flexipages/`: Travel Request Record Page Flexipage
- `force-app/main/default/applications/`: TravelEasy Custom Navigation App

---

## Hackathon Presentation Sequence (20-Minute Demo)

1. **0–2 min**: Business Problem & Spreadsheet Inefficiencies
2. **2–4 min**: Platform Architecture & Smart Expense Control Vision
3. **4–7 min**: Travel Request Creation & Validation Rules
4. **7–12 min**: Expense Submission & Smart Expense Control (Normal vs Exception)
5. **12–16 min**: Trip Wallet LWC & Asynchronous Reimbursement Integration
6. **16–20 min**: Technical Excellence (Bulkification, Security, Async Architecture & Testing)