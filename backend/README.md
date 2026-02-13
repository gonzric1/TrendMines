# TrendMines Backend API

Rails API backend for the TrendMines product discovery pipeline.

## Overview

This is a Rails 8.1 API-only application that powers the TrendMines product discovery system for an Etsy 3D printing business. It provides REST API endpoints for managing signals, niches, cultural tokens, designs, products, and listings.

## Tech Stack

- **Framework**: Ruby on Rails 8.1.2 (API mode)
- **Database**: SQLite 3
- **Ruby Version**: 4.0.0

## Getting Started

### Installation

```bash
# Install dependencies
bundle install

# Create and setup database
rails db:create
rails db:migrate
rails db:seed

# Start the server
rails server
```

The API will be available at `http://localhost:3000`

## API Documentation

### Authentication

All API requests require an API key in the `X-API-Key` header:

```bash
curl -H "X-API-Key: dev-api-key-change-in-production" \
  http://localhost:3000/api/v1/trend_signals
```

### Endpoints

All endpoints are under `/api/v1/` and return JSON with pagination.

See inline controller documentation for complete endpoint details:
- TrendSignals: `/api/v1/trend_signals`
- Niches: `/api/v1/niches`
- CulturalTokens: `/api/v1/cultural_tokens`
- Designs: `/api/v1/designs`
- Products: `/api/v1/products`
- Listings: `/api/v1/listings`

## Data Model

TrendSignal → Niche → CulturalToken → Design → Product → Listing → MetricSnapshot
