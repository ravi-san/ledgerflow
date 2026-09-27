# LedgerFlow Frontend

React 18 dashboard built with Vite, Tailwind CSS, Zustand, ActionCable, and Lucide icons.

## Requirements

- Node.js 20+
- npm
- LedgerFlow backend running at `http://localhost:3001`

## Setup and run

```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

Open `http://localhost:5173`.

The default `.env` setting is:

```bash
VITE_API_URL=http://localhost:3001
```

When the backend uses another host or port, update `VITE_API_URL` and restart Vite.

## Login

Use a seeded backend account:

```text
Email: admin@example.com
Password: Admin@123
```

The login form validates passwords with these requirements:

- At least 8 characters
- At least one uppercase letter
- At least one number
- At least one special character

## Main workflows

### Teams

- Use `New` in the sidebar to create a team.
- Admins can rename the active team in `Settings`.
- Admins see the Team ID and secure join code in `Settings`.
- A new user selects `Join` in the sidebar and enters both values.
- A joined user starts as Viewer. Admins use `Members` to change the role.

### Expenses and audit history

- Creators and Admins create and edit expenses.
- The editor sends `lock_version`; the UI reloads the current record after a `409 Conflict` from a concurrent edit.
- Selecting an expense opens its approval history, reimbursement controls, audit trail, and version comparison.

### Imports

- Creators and Admins can upload CSV rows.
- Imports are queued for Sidekiq and initially appear as pending review.
- Authorized users can accept/reject individual records or use bulk actions.

## API integration

All HTTP requests are centralized in [`src/services/api.js`](src/services/api.js). The client adds the JWT bearer token, converts errors into `ApiError`, normalizes JSON:API audit data, and uses `PUT /teams/:id` for team name updates.

Real-time invalidation events are handled in [`src/hooks/useTeamCable.js`](src/hooks/useTeamCable.js). The frontend reloads authorized team data after an ActionCable event.

## Production build

```bash
npm run build
npm run preview
```

## CORS troubleshooting

The frontend origin must be allowed by the Rails backend. The default Vite URL, `http://localhost:5173`, is already permitted. Restart Rails after changing `FRONTEND_ORIGINS`.
