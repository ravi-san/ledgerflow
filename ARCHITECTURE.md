# LedgerFlow Architecture

## Repository layout

```text
LedgerFlow/
├── backend/                 Rails 7.1 JSON API
│   ├── app/controllers/     HTTP boundary and strong parameters
│   ├── app/models/          Persistence and database relationships
│   ├── app/policies/        Pundit authorization and tenant scopes
│   ├── app/services/        Transactional business workflows
│   ├── app/jobs/            Sidekiq-backed imports
│   ├── app/channels/        Authorized ActionCable subscriptions
│   ├── db/                  PostgreSQL migrations and seeds
│   └── spec/                RSpec request and service coverage
├── frontend/                Vite, React, and TailwindCSS
│   ├── src/components/      Domain UI and dialogs
│   ├── src/hooks/           ActionCable lifecycle
│   ├── src/services/        Centralized API client
│   ├── src/utils/           Display formatting
│   └── src/store.js         Persisted Zustand session/domain store
├── API.md                   Endpoint contract
├── ARCHITECTURE.md          System decisions
└── docker-compose.yml       PostgreSQL and Redis
```

## Request flow

```text
React component
  -> centralized ApiClient
  -> Rails controller
  -> Pundit policy/scope
  -> service transaction
  -> PostgreSQL
  -> after_commit ActionCable event
  -> authorized team clients reload through ApiClient
  -> Zustand store updates the UI
```

The frontend never accesses `fetch` outside `src/services/api.js`. JWTs, selected-team state, and loaded API collections are held in Zustand. Only the JWT, current user, and selected team ID are persisted; mutable collections are reloaded from the authorized API.

## Backend boundaries

- Controllers authenticate, authorize, validate parameters, and map errors to HTTP responses.
- Pundit policies enforce both role permissions and team tenancy.
- `ExpenseUpdater` owns locked updates, optimistic-version checks, and atomic audit creation.
- `ExpenseWorkflow` owns approval and reimbursement transitions inside database transactions.
- `ExternalTransactionReview` locks imported rows and atomically creates accepted expenses.
- `ImportTransactionsJob` uses the unique provider identity index as its retry-safe idempotency boundary.
- `TeamBroadcaster` publishes compact invalidation events only after commit.

## Frontend boundaries

- `services/api.js` defines every HTTP endpoint and authorization header.
- `store.js` owns session, team selection, expenses, imports, and memberships.
- `useTeamCable` manages WebSocket subscription setup and cleanup.
- Domain components contain UI state but delegate all remote mutation to `App.jsx` orchestration.
- TailwindCSS supplies the design system through reusable component classes in `index.css`.

## Concurrency and audit consistency

The client sends `lock_version` with expense updates. If another user saved first, Rails returns `409 Conflict` and the frontend reloads the current record instead of silently overwriting it. Expense writes and audit rows share the same PostgreSQL transaction. A failed audit insert rolls back the business write.

## Security model

- Bearer JWT authentication produces `current_user`.
- All tenant-owned records are authorized server-side; hidden buttons are only a usability feature.
- ActionCable verifies team membership before streaming.
- Join codes are random, unique, and exposed only to team Admins.
- Viewer is read-only; Creator creates and submits owned expenses and reviews imports; Approver decides workflows; Admin manages roles and final payment.

## Production extensions

Add refresh-token rotation or OIDC, pagination, rate limiting, receipt object storage, structured audit export, dead-job alerting, Redis/PostgreSQL high availability, and observability before a production rollout.

## Key decisions and trade-offs

### PostgreSQL transactions over asynchronous audit writes

Expense changes and their audit events are committed in one database transaction. This gives a strong financial-history guarantee: no committed business change exists without an audit record. The trade-off is that audit persistence is on the synchronous request path, so audit table availability and performance matter.

### Optimistic locking over long-lived database locks

The API uses `lock_version` and returns `409 Conflict` for stale edits. This avoids holding database locks while users keep an edit screen open and scales better for normal collaboration. The trade-off is that the client must reload and ask the user to reapply a change after a conflict.

### Event invalidation over broadcasting complete records

ActionCable broadcasts IDs and versions after commit, then clients reload through authorized HTTP endpoints. This avoids exposing sensitive payloads in pub/sub messages and keeps one authorization path. The trade-off is an extra read after each event.

### Join codes over direct email invitations

Random join codes provide a small, self-contained onboarding flow without outbound email infrastructure. Admins still control roles after joining. The trade-off is that join codes must be shared securely and there is no invitation expiry, revocation, or email audit trail yet.

### JSONB audit deltas over a full revision table

`expense_audits.changeset` stores only changed values, which keeps simple edits compact and makes a human-readable audit trail straightforward. Version comparison reconstructs state from ordered deltas. The trade-off is that comparing distant versions requires replaying audit events; snapshot checkpoints can be introduced if the history becomes very large.

### Idempotency at the database boundary

The unique `(team_id, external_id)` index makes import retry safety independent of Sidekiq process behavior. This is stronger than checking only in application memory. The trade-off is that an external provider must supply a stable transaction identity; otherwise, an import fingerprint strategy is required.
