# Rails API Reference

## Base URL

```
http://localhost:3000/api/v1
```

Production URLs will vary by deployment environment.

## Authentication

The API supports **dual authentication** to serve both automated clients (OpenClaw) and human users (dashboard):

### Method 1: API Key (for OpenClaw automation)

Include the API key in the request header:

```http
X-API-Key: your-api-key-here
```

**Configuration:**
- Set `API_KEY` environment variable
- Test environment defaults to `test-api-key-for-test-suite`
- Production requires explicit configuration (fails hard if not set)

**Example:**
```bash
curl -H "X-API-Key: abc123" http://localhost:3000/api/v1/trend_signals
```

### Method 2: JWT/Session (for dashboard users)

User authentication via Devise with JWT tokens:

**Login:**
```http
POST /api/v1/auth/sign_in
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user"
}
```

The JWT token is returned in the `Authorization` header and should be included in subsequent requests.

**Register:**
```http
POST /api/v1/auth/sign_up
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password",
    "password_confirmation": "password",
    "name": "John Doe"
  }
}
```

**Logout:**
```http
DELETE /api/v1/auth/sign_out
Authorization: Bearer <jwt-token>
```

This adds the token to a denylist to invalidate it.

### Authentication Flow

The API attempts authentication in this order:
1. Check for `X-API-Key` header
2. If API key is valid, authenticate as API client
3. If no API key, attempt user JWT/session authentication
4. If neither succeeds, return 401 Unauthorized

## Pagination

All collection endpoints support pagination with consistent format:

**Request Parameters:**
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

**Example:**
```http
GET /api/v1/niches?page=2&per_page=50
```

**Response Format:**
```json
{
  "data": [
    { "id": 1, "name": "..." },
    { "id": 2, "name": "..." }
  ],
  "meta": {
    "total": 150,
    "page": 2,
    "per_page": 50,
    "total_pages": 3
  }
}
```

The `meta` object provides:
- `total` - Total count of records matching query
- `page` - Current page number
- `per_page` - Items per page
- `total_pages` - Total pages available

## Sorting

Collection endpoints support sorting via the `sort` parameter:

**Format:**
```
?sort=<column> <direction>
```

**Direction:**
- `ASC` - Ascending order
- `DESC` - Descending order (case-sensitive)

**Example:**
```http
GET /api/v1/niches?sort=demand_supply_ratio DESC
```

**SQL Injection Protection:**
- Column names are validated against a whitelist
- Only ASC/DESC allowed for direction
- Invalid columns return 400 Bad Request
- See each endpoint for allowed sort columns

## Error Responses

Standard error format:

**Validation Errors (422 Unprocessable Entity):**
```json
{
  "errors": [
    "Name can't be blank",
    "Status can't be blank"
  ]
}
```

**Unauthorized (401):**
```json
{
  "error": "Unauthorized"
}
```

**Not Found (404):**
```json
{
  "error": "Record not found"
}
```

**Bad Request (400):**
```json
{
  "error": "Invalid sort column. Allowed: name, status, created_at"
}
```

**Server Error (500):**
```json
{
  "error": "Server misconfiguration"
}
```

## Health Check

**Endpoint:** `GET /up`

Returns 200 if the app boots successfully, 500 otherwise. Used by load balancers and monitoring tools.

---

## Trend Signals API

**Base Path:** `/api/v1/trend_signals`

Manages early trend signals detected from external sources.

### List Trend Signals
```http
GET /api/v1/trend_signals
```

**Query Parameters:**
- `status` - Filter by status (new, watching, promoted, archived)
- `sort` - Sort order (allowed: id, topic, source, momentum_score, status, created_at, updated_at)
- `page`, `per_page` - Pagination

**Example:**
```http
GET /api/v1/trend_signals?status=watching&sort=momentum_score DESC&page=1&per_page=25
```

### Get Trend Signal
```http
GET /api/v1/trend_signals/:id
```

### Create Trend Signal
```http
POST /api/v1/trend_signals
Content-Type: application/json

{
  "trend_signal": {
    "source": "reddit",
    "topic": "cottage core fashion",
    "description": "Growing interest in rural aesthetic",
    "momentum_score": 0.85,
    "raw_data": { "subreddit": "cottagecore", "posts": 1500 },
    "status": "new",
    "first_seen": "2026-02-14T10:00:00Z"
  }
}
```

### Update Trend Signal
```http
PATCH /api/v1/trend_signals/:id
Content-Type: application/json

{
  "trend_signal": {
    "status": "watching",
    "momentum_score": 0.92
  }
}
```

### Delete Trend Signal
```http
DELETE /api/v1/trend_signals/:id
```

Archives the signal (soft delete).

### Get Signal History
```http
GET /api/v1/trend_signals/:id/history
```

Returns historical momentum scores for the signal.

---

## Niches API

**Base Path:** `/api/v1/niches`

Manages market niches identified from trend signals.

### List Niches
```http
GET /api/v1/niches
```

**Query Parameters:**
- `status` - Filter by status (discovered, evaluating, mining_tokens, generating_designs, active, declining, archived)
- `sort` - Sort order (allowed: id, name, status, demand_score, supply_score, demand_supply_ratio, ao3_works_count, ao3_growth_rate, etsy_listing_count, created_at, updated_at, discovered_at)
- `page`, `per_page` - Pagination

**Default Sort:** `demand_supply_ratio DESC`

### Get Niche
```http
GET /api/v1/niches/:id
```

### Create Niche
```http
POST /api/v1/niches
Content-Type: application/json

{
  "niche": {
    "trend_signal_id": 1,
    "name": "Cottage Core Stickers",
    "description": "Rustic, rural aesthetic sticker designs",
    "community_type": "lifestyle",
    "demand_score": 8.5,
    "supply_score": 3.2,
    "demand_supply_ratio": 2.66,
    "ao3_works_count": 5000,
    "ao3_growth_rate": 0.15,
    "etsy_listing_count": 850,
    "status": "discovered"
  }
}
```

### Update Niche
```http
PATCH /api/v1/niches/:id
```

### Delete Niche
```http
DELETE /api/v1/niches/:id
```

Archives the niche (soft delete).

### Get Niche Tokens
```http
GET /api/v1/niches/:id/tokens
```

Returns all cultural tokens extracted from this niche.

### Get Niche Designs
```http
GET /api/v1/niches/:id/designs
```

Returns all designs generated from this niche's tokens.

### Get Niche Scorecard
```http
GET /api/v1/niches/:id/scorecard
```

Returns comprehensive demand/supply analysis:
```json
{
  "niche": { "id": 1, "name": "...", ... },
  "demand_score": 8.5,
  "supply_score": 3.2,
  "demand_supply_ratio": 2.66,
  "ao3_metrics": {
    "works_count": 5000,
    "growth_rate": 0.15
  },
  "etsy_listing_count": 850
}
```

---

## Cultural Tokens API

**Base Path:** `/api/v1/cultural_tokens`

Manages cultural elements extracted from niches.

### List Cultural Tokens
```http
GET /api/v1/cultural_tokens
```

**Query Parameters:**
- `status` - Filter by status (extracted, designs_pending, designs_ready, in_production, listed)
- `sort` - Sort order (allowed: id, value, token_type, status, composite_score, frequency_score, emotional_intensity, visual_potential, uniqueness_score, created_at, updated_at)
- `page`, `per_page` - Pagination

**Default Sort:** `composite_score DESC`

### Get Cultural Token
```http
GET /api/v1/cultural_tokens/:id
```

### Create Cultural Token
```http
POST /api/v1/cultural_tokens
Content-Type: application/json

{
  "cultural_token": {
    "niche_id": 1,
    "token_type": "phrase",
    "value": "cottagecore vibes",
    "composite_score": 0.87,
    "frequency_score": 0.9,
    "emotional_intensity": 0.75,
    "visual_potential": 0.95,
    "uniqueness_score": 0.88,
    "source_references": [
      { "source": "reddit", "url": "https://..." }
    ],
    "status": "extracted"
  }
}
```

### Update Cultural Token
```http
PATCH /api/v1/cultural_tokens/:id
```

### Delete Cultural Token
```http
DELETE /api/v1/cultural_tokens/:id
```

### Get Token Sources
```http
GET /api/v1/cultural_tokens/:id/sources
```

Returns detailed source references for where the token was found.

### Generate Designs
```http
POST /api/v1/cultural_tokens/:id/generate
```

Triggers AI design generation for this token.

---

## Designs API

**Base Path:** `/api/v1/designs`

Manages AI-generated design concepts.

### List Designs
```http
GET /api/v1/designs
```

**Query Parameters:**
- `status` - Filter by status (pending_review, approved, rejected, needs_revision)
- `sort` - Sort order (allowed: id, design_type, style, status, generation_cost, created_at, updated_at)
- `page`, `per_page` - Pagination

### Get Design
```http
GET /api/v1/designs/:id
```

### Create Design
```http
POST /api/v1/designs
Content-Type: application/json

{
  "design": {
    "cultural_token_id": 1,
    "design_type": "graphic",
    "style": "minimalist",
    "prompt_used": "Minimalist cottagecore aesthetic sticker...",
    "image_url": "https://...",
    "generation_cost": 0.05,
    "status": "pending_review"
  }
}
```

### Update Design
```http
PATCH /api/v1/designs/:id
Content-Type: application/json

{
  "design": {
    "status": "approved"
  }
}
```

### Delete Design
```http
DELETE /api/v1/designs/:id
```

### Regenerate Design
```http
POST /api/v1/designs/:id/regenerate
Content-Type: application/json

{
  "prompt": "New prompt with different style..."
}
```

Generates a new design variant with updated prompt.

---

## Products API

**Base Path:** `/api/v1/products`

Manages physical print-on-demand products.

### List Products
```http
GET /api/v1/products
```

**Query Parameters:**
- `status` - Filter by status (prototype, listed, scaling, declining, retired)
- `sort` - Sort order (allowed: id, name, product_type, status, unit_cost, target_price, margin_pct, created_at, updated_at)
- `page`, `per_page` - Pagination

### Get Product
```http
GET /api/v1/products/:id
```

### Create Product
```http
POST /api/v1/products
Content-Type: application/json

{
  "product": {
    "design_id": 1,
    "product_type": "sticker",
    "name": "Cottagecore Vibes Sticker",
    "unit_cost": 0.50,
    "target_price": 3.99,
    "margin_pct": 87.5,
    "print_time_minutes": 5,
    "units_per_batch": 50,
    "stl_file_url": null,
    "status": "prototype"
  }
}
```

### Update Product
```http
PATCH /api/v1/products/:id
```

### Delete Product
```http
DELETE /api/v1/products/:id
```

### Get Product Listings
```http
GET /api/v1/products/:id/listings
```

Returns all marketplace listings for this product.

### Get Product Metrics
```http
GET /api/v1/products/:id/metrics
```

Returns aggregated performance metrics across all listings.

### List Product
```http
POST /api/v1/products/:id/list
Content-Type: application/json

{
  "platform": "etsy",
  "title": "Cottagecore Aesthetic Sticker",
  "price": 3.99
}
```

Creates a new marketplace listing for this product.

---

## Listings API

**Base Path:** `/api/v1/listings`

Manages marketplace listings for products.

### List Listings
```http
GET /api/v1/listings
```

**Query Parameters:**
- `status` - Filter by status (draft, active, sold_out, paused)
- `sort` - Sort order (allowed: id, title, status, price, created_at, updated_at, listed_at)
- `page`, `per_page` - Pagination

### Get Listing
```http
GET /api/v1/listings/:id
```

### Create Listing
```http
POST /api/v1/listings
Content-Type: application/json

{
  "listing": {
    "product_id": 1,
    "title": "Cottagecore Aesthetic Sticker",
    "price": 3.99,
    "etsy_listing_id": "123456789",
    "status": "draft"
  }
}
```

### Update Listing
```http
PATCH /api/v1/listings/:id
```

### Delete Listing
```http
DELETE /api/v1/listings/:id
```

### Get Listing Metrics
```http
GET /api/v1/listings/:id/metrics
```

Returns time-series metrics for this listing.

### Create Metric Snapshot
```http
POST /api/v1/listings/:id/metrics
Content-Type: application/json

{
  "metric_snapshot": {
    "views": 150,
    "favorites": 12,
    "sales": 3,
    "revenue": 11.97,
    "fav_view_ratio": 0.08,
    "captured_at": "2026-02-14T12:00:00Z"
  }
}
```

### Get Alerts
```http
GET /api/v1/listings/alerts
```

Returns listings with performance anomalies (decay detection).

### Get Leaderboard
```http
GET /api/v1/listings/leaderboard
```

Returns top-performing listings sorted by revenue or sales.

---

## Common Patterns

### Filtering
Use `status` query parameter on any collection endpoint:
```http
GET /api/v1/niches?status=active
```

### Sorting
Use `sort` parameter with column and direction:
```http
GET /api/v1/cultural_tokens?sort=composite_score DESC
```

### Pagination
Use `page` and `per_page` parameters:
```http
GET /api/v1/products?page=2&per_page=50
```

### Combining Parameters
All parameters can be combined:
```http
GET /api/v1/listings?status=active&sort=revenue DESC&page=1&per_page=10
```

### Soft Deletes
DELETE endpoints typically soft delete by setting status to archived:
```http
DELETE /api/v1/niches/:id
# Sets status to 'archived' instead of deleting record
```

---

## Rate Limiting

⚠️ **Not yet implemented**

Future: Rate limiting will be enforced based on authentication method:
- API key: 1000 requests/hour
- User session: 100 requests/hour

---

## Versioning

Current API version: **v1**

All endpoints are prefixed with `/api/v1`. Future versions will use `/api/v2`, etc.

Breaking changes will always increment the major version number.

---

## Related Documentation

- [Architecture Overview](./architecture.md) - System design and data flow
- [Models Reference](./models.md) - Domain model details
- [Etsy Integration](../integrations/etsy.md) - Marketplace integration
