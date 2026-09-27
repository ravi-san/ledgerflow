# LedgerFlow Backend

Rails 7.1 API for collaborative team expense tracking. It uses PostgreSQL, Sidekiq, Redis, JWT authentication, Pundit authorization, ActionCable, and `jsonapi-serializer`.

## Requirements

- Ruby 3.3+
- Bundler
- PostgreSQL 16+
- Redis 7+

Start PostgreSQL and Redis with the repository Docker Compose file:

```bash
cd ..
docker compose up -d
```

## Setup and run

```bash
cd backend
bundle install
export DATABASE_URL=postgres://ledgerflow:ledgerflow@localhost:5432/ledgerflow_development
bin/rails db:prepare
bin/rails db:seed
bin/rails server -p 3001
```

Run Sidekiq in a second terminal for transaction imports:

```bash
cd backend
export DATABASE_URL=postgres://ledgerflow:ledgerflow@localhost:5432/ledgerflow_development
export REDIS_URL=redis://localhost:6379/0
bundle exec sidekiq
```

API base URL: `http://localhost:3001`

## Seed accounts

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@example.com` | `Admin@123` |
| Creator | `creator@example.com` | `Creator@123` |
| Approver | `approver@example.com` | `Approver@123` |
| Viewer | `viewer@example.com` | `Viewer@123` |

New passwords must be at least eight characters and include an uppercase letter, number, and special character.

## Authentication

```http
POST /auth/login
Content-Type: application/json

{ "email": "admin@example.com", "password": "Admin@123" }
```

Send the returned token on protected requests:

```http
Authorization: Bearer <token>
```

## Roles

| Role | Permissions |
| --- | --- |
| Viewer | Read team data, expenses, and audit history |
| Creator | Viewer access plus create/update eligible expenses and imports |
| Approver | Viewer access plus approve/reject and process reimbursements |
| Admin | Full team, membership, role, and final payment management |

## Team membership

`POST /teams` creates a team and makes the creator an Admin. Admins receive the team `join_code` in `GET /teams` and `GET /teams/:id` responses.

Another user joins with:

```http
POST /teams/:id/join
Authorization: Bearer <token>
Content-Type: application/json

{ "join_code": "shared-team-code" }
```

Joined users start as `viewer`. Admins can update a membership role using `PATCH /teams/:team_id/memberships/:id`. Trying to join a team already joined returns `409` with `already_a_member`.

## Main endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| POST | `/auth/login` | Get JWT token |
| GET, POST | `/teams` | List or create teams |
| GET, PUT, PATCH | `/teams/:id` | Read or rename a team |
| POST | `/teams/:id/join` | Join a team with join code |
| GET, PATCH, DELETE | `/teams/:team_id/memberships/:id` | Manage team roles |
| GET, POST | `/teams/:team_id/expenses` | List or create expenses |
| GET, PATCH, DELETE | `/expenses/:id` | Read, update, or soft-delete an expense |
| GET | `/expenses/:id/audit_trail` | JSON:API audit history |
| GET | `/expenses/:id/compare?from=:id&to=:id` | Compare audit versions |
| POST | Expense workflow endpoints | Submit, approve, reject, reimburse, process, or pay |
| GET, POST | `/teams/:team_id/imports` | List or queue imports |
| POST | Import review endpoints | Accept, reject, or bulk-review imports |

See [`../API.md`](../API.md) for the full API contract.

## Audit response

`GET /expenses/:id/audit_trail` returns a JSON:API document. It exposes the action, meaningful field changes, timestamp, and actor email. Internal fields such as `team_id`, `member_id`, `deleted_at`, and `lock_version` are not returned in the changeset.

## Test

```bash
cd backend
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

## CORS

The default allowed frontend origins are `http://localhost:5173` and `http://127.0.0.1:5173`. Configure additional origins before starting Rails:

```bash
FRONTEND_ORIGINS=http://localhost:5173,http://example.com bin/rails server -p 3001
```
