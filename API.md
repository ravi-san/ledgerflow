# LedgerFlow API

Base URL: `http://localhost:3001`. JSON requests use `Content-Type: application/json`. Except login, send `Authorization: Bearer <jwt>`.

## Authentication

### `POST /auth/login`

```json
{ "email": "admin@example.com", "password": "Password@123" }
```

Returns `{ "token": "...", "user": { ... } }`. Invalid credentials return `401`.

## Teams and memberships

| Method | Path | Permission | Body |
| --- | --- | --- | --- |
| GET | `/teams` | Authenticated | - |
| POST | `/teams` | Authenticated | `{ "name": "Operations" }` |
| GET | `/teams/:id` | Member | - |
| PATCH | `/teams/:id` | Admin | `{ "name": "New name" }` |
| POST | `/teams/:id/join` | Non-member | `{ "join_code": "..." }` |
| GET | `/teams/:team_id/memberships` | Admin | - |
| PATCH | `/teams/:team_id/memberships/:id` | Admin | `{ "role": "approver" }` |
| DELETE | `/teams/:team_id/memberships/:id` | Admin | - |

Team list/show responses include `current_role`; Admin responses also include `join_code`. The last Admin cannot be demoted or removed.

## Expenses

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/teams/:team_id/expenses` | Member | Active team expenses |
| POST | `/teams/:team_id/expenses` | Creator/Admin | Create draft |
| GET | `/expenses/:id` | Member | Expense, approval steps, reimbursement |
| PATCH | `/expenses/:id` | Creator/Admin | Update with `lock_version` |
| DELETE | `/expenses/:id` | Admin | Audited soft delete |
| GET | `/expenses/:id/audit_trail` | Member | Ordered audit records |
| GET | `/expenses/:id/compare?from=:audit_id&to=:audit_id` | Member | Reconstructed version diff |

Create/update fields:

```json
{
  "amount_cents": 8750,
  "description": "Client workshop supplies",
  "spent_on": "2026-09-26",
  "category": "operations",
  "lock_version": 4
}
```

`lock_version` is required only for update. A stale update returns `409` with the current record.

## Workflow

| Method | Path | Permission |
| --- | --- | --- |
| POST | `/expenses/:id/submit` | Owning Creator/Admin |
| POST | `/expenses/:id/approve` | Approver/Admin |
| POST | `/expenses/:id/reject` | Approver/Admin |
| POST | `/expenses/:id/reimburse` | Approver/Admin |
| POST | `/expenses/:id/process_reimbursement` | Approver/Admin |
| POST | `/expenses/:id/pay_reimbursement` | Admin |

Reject body: `{ "reason": "Receipt is missing" }`.

```text
draft or pending_review -> submitted -> approved -> reimbursed
                               |             |
                               v             v
                            rejected   requested -> processing -> paid
```

## External imports

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/teams/:team_id/imports` | Member | Imported transaction list |
| POST | `/teams/:team_id/imports` | Creator/Admin | Queue Sidekiq import |
| GET | `/imports/:id` | Member | One imported transaction |
| POST | `/imports/:id/accept` | Creator/Admin | Create pending-review expense |
| POST | `/imports/:id/reject` | Creator/Admin | Reject source row |
| POST | `/imports/bulk_accept` | Creator/Admin | Accept `ids` array |
| POST | `/imports/bulk_reject` | Creator/Admin | Reject `ids` array |

Queue body:

```json
{
  "rows": [
    {
      "external_id": "bank-2026-1001",
      "amount_cents": 6400,
      "description": "Card transaction",
      "transacted_on": "2026-09-26"
    }
  ]
}
```

## Real-time channel

Connect to `/cable?token=<jwt>` and subscribe with:

```json
{ "channel": "TeamChannel", "team_id": 1 }
```

Events are `expense.changed` and `audit.changed`. They contain IDs and versions; clients reload authorized HTTP resources after receipt.

## Error responses

| Status | Meaning |
| --- | --- |
| 401 | Missing, invalid, or expired JWT |
| 403 | Authenticated but not permitted |
| 404 | Record not found or inaccessible through scoped lookup |
| 409 | Optimistic-lock conflict |
| 422 | Invalid parameters, validation, or workflow transition |
