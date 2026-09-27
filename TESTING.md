# Test Coverage

The backend uses RSpec request, model, and service tests. Run the suite with:

```bash
cd backend
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

The frontend is verified with a production build:

```bash
cd frontend
npm run build
```

## Latest verified result

```text
24 examples, 0 failures
Line coverage: 347 / 471 (73.67%)
```

The HTML report is generated at `backend/coverage/index.html` after every backend test run. The report directory is ignored by Git.

## Coverage matrix

| Area | Coverage |
| --- | --- |
| Authentication | JWT login response excludes `password_digest` |
| Password security | Valid password accepted; missing complexity rejected |
| Authorization | Viewer mutation denial, creator ownership checks, reimbursement payment restriction |
| Tenant access | Pundit-backed team and expense authorization through memberships |
| Team administration | Team creation grants Admin, role changes, last-Admin protection, join-code validation |
| Duplicate joining | Existing member receives `409 already_a_member` |
| CORS | Default allowed origin, preflight, and blocked origin behavior |
| Optimistic locking | Stale expense update returns `409` and preserves the newer value |
| Audit trail | Team member can read audit data; serializer hides internal change fields |
| Audit consistency | Expense updater creates field-level audit changes transactionally |
| Version comparison | Reconstructed audit versions return only meaningful differences |
| Approval workflow | Ordered Manager/Finance approval, rejection, reimbursement progression, payment restrictions |
| Imports | Idempotent job execution, acceptance transaction, rejection, and source-to-expense linking |

## Test organization

```text
backend/spec/
├── models/user_spec.rb
├── requests/
│   ├── auth_spec.rb
│   ├── authorization_spec.rb
│   ├── cors_spec.rb
│   └── teams_spec.rb
└── services/
    ├── expense_updater_spec.rb
    ├── expense_version_comparer_spec.rb
    ├── expense_workflow_spec.rb
    ├── external_transaction_review_spec.rb
    └── import_transactions_job_spec.rb
```

## Remaining test opportunities

- Browser-level end-to-end tests for login, team joining, real-time refresh, and import upload.
- Contract tests for every JSON response, including all JSON:API serializer documents.
- Load and failure-injection tests for Redis, Sidekiq retries, and database contention.
- Security tests for JWT expiration, token revocation strategy, and rate limiting once production authentication is added.
