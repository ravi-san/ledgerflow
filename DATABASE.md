# Database and Schema Design

LedgerFlow uses PostgreSQL as the source of truth. Application validations improve feedback, but foreign keys, unique indexes, and check constraints enforce critical invariants at the database layer.

## Entity relationship overview

```text
User --< Membership >-- Team --< Expense --< ExpenseAudit
                                  |  \--< ApprovalStep
                                  \----- Reimbursement

Team --< ExternalTransaction >-- Expense (optional after acceptance)
```

## Tables

### `users`

Stores authenticated identities: unique `email` and BCrypt `password_digest`. Password complexity is validated in the model; the digest, never the password, is persisted.

### `teams`

Tenant boundary for all financial data. `join_code` is a random, unique token used for self-service team joining. It is exposed only to Admin members in API responses.

### `memberships`

Join table between users and teams. `role` is an enum: `viewer`, `creator`, `approver`, and `admin`.

The unique index on `(user_id, team_id)` prevents duplicate membership rows, including concurrent join requests. This table is the authorization boundary used by Pundit policies and query scopes.

### `expenses`

The mutable ledger record. It belongs to a team and a member, and stores money as integer `amount_cents` to avoid floating-point rounding. It contains:

- `status` for draft, review, approval, reimbursement, and rejection transitions
- `lock_version` for optimistic locking
- `deleted_at` for auditable soft deletion

The database checks that `amount_cents > 0` and that status is a permitted enum value. Team/date and team/status indexes support the dashboard and approval queue queries.

### `expense_audits`

Append-only audit events for expense create, update, delete, and workflow actions. `changeset` is JSONB with field-level `old` and `new` values. Each audit records the actor, action, and timestamp.

The `(expense_id, created_at)` index supports ordered audit history. Expense writes and audit inserts run in the same transaction, so an expense change cannot commit without its audit row.

### `approval_steps`

Preserves the multi-step Manager and Finance approval decisions. It records the stage, decision, deciding user, timestamp, and optional rejection reason.

The unique `(expense_id, stage)` index ensures one durable record per approval stage. This makes approval history explicit rather than inferring it from current expense status.

### `reimbursements`

One-to-one aggregate separated from the expense because payout processing has its own lifecycle: `requested`, `processing`, `paid`, and `failed`. The unique `expense_id` index prevents two reimbursements for one expense.

### `external_transactions`

Staging table for bank-feed or CSV rows. Imported records begin as `pending_review`; accepted records point to the expense created from them.

The unique `(team_id, external_id)` index is the idempotency key. Sidekiq retries and duplicate import submissions cannot create a second source transaction or second accepted expense for the same provider identity.

## Referential integrity

All ownership and actor references use foreign keys. This prevents orphaned expenses, audit records, approval steps, reimbursements, imports, and memberships. Dependencies are chosen intentionally: expenses are not casually deleted because their financial history must remain intact.

## Concurrency and consistency

`expenses.lock_version` prevents lost updates. A client sends the version it read; a stale writer receives `409 Conflict` and the current expense instead of silently replacing newer data.

For accepted imports and expense updates, PostgreSQL transactions and row locks protect multi-record operations. Database uniqueness constraints remain the final guard when two processes race.

