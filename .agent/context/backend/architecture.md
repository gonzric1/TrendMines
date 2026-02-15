# Rails Backend Architecture

## Overview

The TrendMines Rails backend is a JSON API that powers the product discovery pipeline. It manages the lifecycle of trend signals as they flow through evaluation, design generation, and marketplace listing stages.

**Key Characteristics:**
- **API-first**: Built as a REST API with versioning (currently v1)
- **Dual authentication**: Supports both API keys (for OpenClaw automation) and JWT/session tokens (for dashboard users)
- **SQLite database**: Lightweight persistence for rapid prototyping
- **Pipeline state machine**: Resources track their lifecycle through status enums
- **Fully documented**: YARD documentation on all controllers and models

## Architecture Pattern

The backend follows Rails conventions with a clear separation of concerns:

```
backend/
├── app/
│   ├── controllers/
│   │   ├── api/v1/               # Versioned API controllers
│   │   │   ├── base_controller.rb  # Authentication, pagination, sorting
│   │   │   ├── auth/               # Devise authentication endpoints
│   │   │   └── *_controller.rb     # Resource controllers
│   │   └── application_controller.rb
│   └── models/
│       ├── application_record.rb
│       └── *.rb                    # Domain models with enums and scopes
├── config/
│   ├── routes.rb                   # RESTful routes with member actions
│   └── initializers/
│       └── devise.rb               # JWT authentication config
└── db/
    ├── schema.rb                   # Database structure
    └── migrate/                    # Migrations
```

## Data Flow Through the Pipeline

The TrendMines pipeline transforms raw trend signals into marketplace-ready products through a series of stages:

```mermaid
flowchart LR
    TS[Trend Signal] -->|Evaluated| N[Niche]
    N -->|Tokens Extracted| CT[Cultural Token]
    CT -->|AI Generated| D[Design]
    D -->|Prototyped| P[Product]
    P -->|Listed| L[Listing]
    L -->|Monitored| MS[Metric Snapshot]

    style TS fill:#4a9eff
    style N fill:#2d6a4f
    style CT fill:#6a4c93
    style D fill:#e76f51
    style P fill:#f4a261
    style L fill:#e9c46a
    style MS fill:#264653
```

### Stage Details

1. **Trend Signal → Niche**
   - OpenClaw scans external sources (AO3, Reddit, TikTok, etc.)
   - Signals with high momentum are evaluated for commercial potential
   - Niches are created when demand/supply ratio looks favorable

2. **Niche → Cultural Tokens**
   - Token extraction identifies cultural elements (phrases, symbols, memes)
   - Tokens are scored on frequency, emotional intensity, visual potential, uniqueness
   - Top tokens move to design generation

3. **Cultural Token → Design**
   - AI generates visual designs from token prompts
   - Designs enter review workflow (pending_review → approved/rejected/needs_revision)
   - Approved designs become product candidates

4. **Design → Product**
   - Products define physical manufacturing specs (cost, pricing, print time)
   - Products track lifecycle status (prototype → listed → scaling → declining → retired)
   - Printer assignments allocate production capacity

5. **Product → Listing**
   - Listings represent marketplace presence (currently Etsy-focused)
   - Status tracks marketplace state (draft → active → sold_out → paused)
   - Multiple listings per product supported (future: multi-marketplace)

6. **Listing → Metrics**
   - Metric snapshots capture time-series performance data
   - Tracks views, favorites, sales, revenue, fav/view ratio
   - Powers alerts, leaderboards, and decay detection

## Pipeline Stages

### 1. Signal Monitoring Stage
**Resources:** `TrendSignal`
**Status Flow:** `new` → `watching` → `promoted` → `archived`
**API Endpoints:** `/api/v1/trend_signals`

OpenClaw scans external sources and creates trend signals. Signals are monitored for momentum. When a signal shows commercial potential, it's promoted to a niche.

**Key Fields:**
- `momentum_score` - Calculated metric for trend strength
- `raw_data` - JSON blob with source-specific data
- `source` - Origin (e.g., 'ao3', 'reddit', 'tiktok')

### 2. Niche Evaluation Stage
**Resources:** `Niche`
**Status Flow:** `discovered` → `evaluating` → `mining_tokens` → `generating_designs` → `active` → `declining` → `archived`
**API Endpoints:** `/api/v1/niches`, `/api/v1/niches/:id/scorecard`

Niches represent market opportunities with demand/supply analysis. The scorecard endpoint provides comprehensive metrics:
- AO3 metrics (works count, growth rate) - proxy for demand
- Etsy listing count - proxy for supply
- Demand/supply ratio - key decision metric

### 3. Token Extraction Stage
**Resources:** `CulturalToken`
**Status Flow:** `extracted` → `designs_pending` → `designs_ready` → `in_production` → `listed`
**API Endpoints:** `/api/v1/cultural_tokens`, `/api/v1/niches/:id/tokens`

Cultural tokens are key elements with design potential. They're scored on multiple dimensions:
- `frequency_score` - How often it appears
- `emotional_intensity` - Sentiment strength
- `visual_potential` - Suitability for visual design
- `uniqueness_score` - Differentiation from competition
- `composite_score` - Overall viability (used for ranking)

### 4. Design Generation Stage
**Resources:** `Design`
**Status Flow:** `pending_review` → `approved` / `rejected` / `needs_revision`
**API Endpoints:** `/api/v1/designs`, `/api/v1/designs/:id/regenerate`

AI-generated designs go through human review. The regenerate action allows retrying with modified prompts. Approved designs become product candidates.

**Key Fields:**
- `prompt_used` - AI prompt that generated the design
- `image_url` - Location of generated image (future: ActiveStorage)
- `style` - Visual style applied
- `generation_cost` - Cost tracking for AI generation

### 5. Product Manufacturing Stage
**Resources:** `Product`, `PrinterAssignment`
**Status Flow:** `prototype` → `listed` → `scaling` → `declining` → `retired`
**API Endpoints:** `/api/v1/products`, `/api/v1/products/:id/list`

Products define manufacturing specs and economics:
- `unit_cost`, `target_price`, `margin_pct` - Economics
- `print_time_minutes`, `units_per_batch` - Production capacity
- `stl_file_url` - 3D print file location

Printer assignments track which printers are allocated to which products.

### 6. Marketplace Listing Stage
**Resources:** `Listing`, `MetricSnapshot`
**Status Flow:** `draft` → `active` → `sold_out` / `paused`
**API Endpoints:**
- `/api/v1/listings`, `/api/v1/listings/alerts`, `/api/v1/listings/leaderboard`
- `/api/v1/products/:id/listings`, `/api/v1/listings/:id/metrics`

Listings represent marketplace presence. Future: multi-marketplace support (Etsy, Amazon, etc.)

**Metrics Tracking:**
- Views, favorites, sales, revenue
- Fav/view ratio (conversion indicator)
- Captured at regular intervals for trend analysis

## Controller Patterns

All API controllers inherit from `Api::V1::BaseController`, which provides:

### Authentication
- **Dual mode**: API key (X-API-Key header) OR user JWT/session
- API key for OpenClaw automation
- User auth for dashboard users
- Fails with 401 if neither succeeds

### Pagination
- `paginate(collection)` - Returns `{data: [...], meta: {total, page, per_page, total_pages}}`
- `render_paginated(collection)` - One-liner: paginate + render
- Default: 25 per page, max 100
- Params: `?page=2&per_page=50`

### Safe Sorting
- `sanitize_sort_params(allowed_columns:, default:)` - SQL injection protection
- Whitelist-based column validation
- Direction validation (ASC/DESC only)
- Usage: `?sort=momentum_score DESC`

## Model Patterns

### Status Enums
All major resources use Rails enums for status tracking:
```ruby
enum :status, {
  state_one: "state_one",
  state_two: "state_two"
}, default: :state_one
```

This provides:
- Database validation
- Scopes (`.state_one`, `.state_two`)
- Predicates (`.state_one?`, `.state_two?`)
- Bang methods (`.state_one!`, `.state_two!`)

### Scopes
Models define reusable query scopes:
```ruby
scope :active, -> { where(status: [:listed, :scaling]) }
scope :by_momentum, -> { order(momentum_score: :desc) }
```

Used for filtering and sorting in controllers.

### Associations
Clear parent-child relationships:
```ruby
TrendSignal
  has_many :niches

Niche
  belongs_to :trend_signal
  has_many :cultural_tokens

CulturalToken
  belongs_to :niche
  has_many :designs

Design
  belongs_to :cultural_token
  has_many :products

Product
  belongs_to :design
  has_many :listings
  has_many :printer_assignments

Listing
  belongs_to :product
  has_many :metric_snapshots
```

## Future Enhancements

### Planned Features
- **ActiveStorage**: Image storage with S3-compatible backends
- **Multi-marketplace**: Expand beyond Etsy to Amazon, Redbubble, etc.
- **Webhook support**: Real-time notifications for OpenClaw

### Technical Debt
- Move from SQLite to PostgreSQL for production
- API key management in database (currently env variable)
- Rate limiting and throttling
- Background job processing (Sidekiq/Good Job)
- Caching layer (Redis)

## Testing Strategy

- **Integration tests**: Full request/response cycle testing
- **Model tests**: Validation and scope testing
- **SimpleCov**: Code coverage tracking (target: 90%+)
- **RuboCop**: Style and best practices enforcement

## Related Documentation

- [API Reference](./api.md) - Endpoint structure, authentication, pagination
- [Models Reference](./models.md) - Domain model relationships and lifecycle states
- [Etsy Integration](../integrations/etsy.md) - Marketplace integration details
- [Security Context](./../security/sql-injection-fix-2026-02-14.md) - Security fixes and best practices
