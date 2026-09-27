# LedgerFlow

LedgerFlow is a multi-user expense ledger for small teams. It combines a Rails JSON API, PostgreSQL, Sidekiq, Redis/ActionCable, Pundit authorization, and a React/Vite dashboard.

## What is included

- Team membership with Viewer, Creator, Approver, and Admin roles
- Draft, submission, two-stage approval, rejection, reimbursement, and paid workflows
- Optimistic locking with `409 Conflict` responses for stale edits
- Transactional, field-level expense audits and version comparison
- ActionCable events for expense and audit changes
- Idempotent external transaction imports through Sidekiq
- Individual and bulk import review
- API-level tenant isolation and role enforcement
- Request and service specs for authorization, concurrency, transaction rollback, workflows, and import idempotency

## Quick start

Prerequisites: Ruby compatible with Rails 7.1, Bundler, Node.js 20+, Docker, and Docker Compose.

Start PostgreSQL and Redis:

```bash
docker compose up -d
```

Prepare and run the API:

```bash
cd backend
bundle install
DATABASE_URL=postgres://ledgerflow:ledgerflow@localhost:5432/ledgerflow_development bin/rails db:prepare db:seed
DATABASE_URL=postgres://ledgerflow:ledgerflow@localhost:5432/ledgerflow_development bin/rails server
```

In a second terminal, run Sidekiq:

```bash
cd backend
DATABASE_URL=postgres://ledgerflow:ledgerflow@localhost:5432/ledgerflow_development bundle exec sidekiq
```

Run the web client:

```bash
cd frontend
npm install
npm run dev
```

Open `http://localhost:5173`. Seeded accounts use the following passwords:

- `admin@example.com` / `Admin@123`
- `creator@example.com` / `Creator@123`
- `approver@example.com` / `Approver@123`
- `viewer@example.com` / `Viewer@123`

The Rails API defaults to `http://localhost:3001`; the frontend runs at `http://localhost:5173`. Override the API URL with `VITE_API_URL` in `frontend/.env` when needed.

## Tests

Create the test database and run the suite:

```bash
cd backend
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

Build the Vite/Tailwind frontend:

```bash
cd frontend
npm run build
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for component and data-flow decisions and [API.md](API.md) for the complete endpoint contract.
See [DATABASE.md](DATABASE.md) for the schema design and [TESTING.md](TESTING.md) for the coverage matrix.



## Schema design

`users` join `teams` through `memberships`, where the role is stored. Every tenant-owned query is scoped through those memberships. Joining requires a random team code exposed only to Admins.

`expenses` stores the mutable ledger record and Rails' `lock_version`. `expense_audits` stores immutable JSONB field deltas with actor and timestamp. Deletes are soft deletes so their history remains queryable. `approval_steps` has one row per expense and stage, preserving the decision, actor, timestamp, and rejection reason. `reimbursements` is a separate one-to-one aggregate because payment processing has a lifecycle distinct from approval.

`external_transactions` preserves source identity. A unique `(team_id, external_id)` index is the idempotency boundary used by the import job. Accepting one locks the source row and atomically creates an expense, its audit, and the source link.

Foreign keys, unique indexes, amount checks, and enum-range checks enforce invariants below the Rails validation layer. Team/date and team/status indexes support common dashboard and review queries.

## Architecture decisions

### Consistent writes and audit records

Expense creation, update, workflow transitions, and soft deletion write their audit rows inside the same PostgreSQL transaction. If audit validation or persistence fails, the business change rolls back. Broadcasts use `after_commit`, so clients never see uncommitted state.

### Concurrent edits

Rails optimistic locking is backed by `expenses.lock_version`. Clients must send the version they edited. `ExpenseUpdater` also locks and checks the row in its transaction, returning `409` plus the current record if another writer won.

### Authorization and tenancy

JWT authentication supplies `current_user`. Pundit policies and scopes enforce tenant access in controllers; team-owned collection lookups are additionally rooted through `current_user.teams`. Viewers are read-only, Creators manage their own expenses and imports, Approvers decide and process reimbursements, and Admins manage roles and final payment.

### Approval and reimbursement

Submission creates Manager and Finance steps. Decisions are ordered and immutable once completed. Reimbursement progresses independently through `requested -> processing -> paid`; paying it moves the expense to `reimbursed`.

### Real-time collaboration

`TeamChannel` verifies membership during subscription. Expense and audit commits publish compact invalidation events; clients then reload authorized API data. This avoids putting sensitive record payloads into Redis and keeps HTTP authorization as the source of truth.

## API overview

- `POST /auth/login`
- `GET/POST /teams`, `GET/PUT/PATCH /teams/:id`, `POST /teams/:id/join`
- `GET/PATCH/DELETE /teams/:team_id/memberships/:id`
- `GET/POST /teams/:team_id/expenses`, `GET/PATCH/DELETE /expenses/:id`
- `GET /expenses/:id/audit_trail`
- `GET /expenses/:id/compare?from=<audit_id>&to=<audit_id>`
- `POST /expenses/:id/submit|approve|reject|reimburse|process_reimbursement|pay_reimbursement`
- `GET/POST /teams/:team_id/imports`
- `GET /imports/:id`, `POST /imports/:id/accept|reject`
- `POST /imports/bulk_accept|bulk_reject`
- WebSocket `/cable?token=<jwt>` with `{ channel: "TeamChannel", team_id: ID }`

## Assumptions and known limitations

See [ASSUMPTIONS.md](ASSUMPTIONS.md) for assumptions, current limitations, and recommended production priorities.

See [backend/README.md](backend/README.md) for backend-focused notes.
