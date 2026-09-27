# Assumptions and Known Limitations

## Assumptions

### Identity and team onboarding

- Users already have accounts. This exercise provides login and seeded users; self-registration, password reset, email verification, and direct email invitations are out of scope.
- An Admin shares a Team ID and random join code with a trusted user. A successful join creates a Viewer membership; an Admin changes the role afterward.
- Join codes are treated as sensitive shared secrets and are exposed only to Admins in API responses.

### Financial data

- Amounts are stored as integer cents, and the demo frontend renders USD. A production system should store an ISO 4217 currency code per expense or team and define conversion policy.
- Expenses represent submitted business expenses, not a complete double-entry accounting ledger. General-ledger accounts, tax treatment, budgets, and accounting period close are outside the scope.
- Timestamps are persisted by Rails/PostgreSQL and displayed in the browser's local time zone.

### Workflow

- Every submitted expense uses the same two stages: Manager followed by Finance.
- Any member with the Approver role can make either approval decision. Per-stage assignees, amount thresholds, delegated approvers, and out-of-office routing are not yet modeled.
- A paid reimbursement moves the expense to `reimbursed`; no external payment provider is called.

### External transactions

- The import UI accepts CSV-style rows and the backend processes normalized transaction data through Sidekiq. It simulates a bank feed rather than connecting to a real financial institution.
- Idempotency assumes an upstream source provides a stable `external_id` per team. For sources without one, a canonical transaction fingerprint would be needed.

## Known limitations

### Authentication and security

- JWTs are bearer tokens with expiry but no refresh-token rotation, revocation list, device/session management, or OIDC integration.
- The ActionCable token is sent in the query string for this demo. A production deployment should avoid query-string credentials and ensure proxy logs redact sensitive values.
- There is no rate limiting, account lockout, CAPTCHA, CSRF/session authentication option, or audit export access policy.
- Join codes do not expire or rotate. Production should support rotation, expiration, and a recorded invitation lifecycle.

### Scale and reliability

- List endpoints are not paginated or filtered beyond the current team/status query patterns. Large teams need pagination, search, cursor-based audit history, and archival strategy.
- Realtime events are invalidations, not full patches. This deliberately favors authorization safety but causes a follow-up HTTP read after each event.
- The import job is idempotent at the source-row boundary. Bulk review executes each item transactionally, but the full batch is not one all-or-nothing transaction.
- There are no retry dashboards, dead-letter monitoring, metrics, tracing, alerting, backup verification, or disaster-recovery runbooks.

### Product scope

- There is no receipt/attachment storage, comments, notifications, email delivery, mobile application, or external accounting sync.
- Team names accept letters and spaces only in the current validation. Internationalized names and punctuation require a revised validation policy.
- The audit API intentionally hides internal fields from its response, while the underlying database history retains them for integrity and reconstruction.
- Current automated coverage is backend-focused: RSpec reports 73.67% line coverage. Frontend behavior is build-verified but does not yet have component or browser end-to-end tests.

## Production priorities

Before production use, prioritize OIDC or rotating refresh tokens, rate limiting, TLS and secure secrets management, invitation rotation, pagination, receipt storage, structured observability, backups, and end-to-end/browser testing.
