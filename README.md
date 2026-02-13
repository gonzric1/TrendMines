# TrendMines

Product discovery pipeline for Etsy 3D printing business. Tracks trend signals, generates niches, cultural tokens, designs, and manages listings.

## Architecture

This is a monorepo with a Rails API backend and React SPA frontend:

```
TrendMines/
├── backend/          # Rails 8.1 API (Ruby 4.0.0, SQLite)
├── frontend/         # React 19 + TypeScript + Vite + shadcn/ui
└── Docs/             # Project documentation
```

## Quick Start

### Backend (Rails API)

```bash
cd backend
bundle install
rails db:create db:migrate db:seed
rails server
```

API runs at `http://localhost:3000`

See [backend/README.md](./backend/README.md) for full documentation.

### Frontend (React SPA)

```bash
cd frontend
npm install
npm run dev
```

Frontend runs at `http://localhost:5173`

See [frontend/README.md](./frontend/README.md) for full documentation.

## API Authentication

All API requests require an API key header:

```bash
curl -H "X-API-Key: dev-api-key-change-in-production" \
  http://localhost:3000/api/v1/trend_signals
```

## Data Pipeline

```
TrendSignal → Niche → CulturalToken → Design → Product → Listing → MetricSnapshot
```

1. **TrendSignal**: Raw trend data from various sources
2. **Niche**: Market segments derived from signals
3. **CulturalToken**: Cultural references/themes within niches
4. **Design**: 3D printable design concepts
5. **Product**: Manufacturable products from designs
6. **Listing**: Etsy marketplace listings
7. **MetricSnapshot**: Performance metrics over time

## Tech Stack

### Backend
- Ruby on Rails 8.1 (API mode)
- SQLite 3
- Ruby 4.0.0

### Frontend
- React 19 with TypeScript
- Vite
- Tailwind CSS
- shadcn/ui
- React Router
- Axios

## Development

Both backend and frontend can run concurrently during development. The frontend is configured to proxy API requests to the backend.

## Project Structure

- `/backend` - Rails API application
- `/frontend` - React SPA application
- `/Docs` - Project documentation
- `/.beads` - Issue tracking (beads workflow)
- `/.agent` - AI agent context and skills

## Contributing

This project uses the beads workflow for task tracking. See `.beads/` for open issues and planning.
