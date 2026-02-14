# TrendMines — Project Bootstrap Guide

> **This file is your starting point.** Read it fully before doing anything else. It tells you what TrendMines is, what the other documents contain, and how to break the work into implementable tickets.

---

## What You're Building

TrendMines is a web application (dashboard + REST API) that powers an automated **trend intelligence and product discovery** pipeline for an Etsy 3D printing business. The system focuses on the insight and discovery side of the business — production, fulfillment, and printer management are handled externally by the operator. The system:

1. **Scans** for cultural trends across AO3, Reddit, Tumblr, Google Trends, TikTok, and Etsy
2. **Identifies** passionate niche communities with high demand and low Etsy supply
3. **Extracts** specific cultural tokens (quotes, symbols, ship names, in-jokes) that fans would buy
4. **Generates** product design candidates using the Gemini API (Nano Banana / Nano Banana Pro)
5. **Suggests** prototype candidates for human review — the operator decides what to actually produce and list
6. **Monitors** listing performance and detects when products are declining

An **OpenClaw** AI assistant runs 24/7 and handles all the automated scanning, scoring, extraction, and design generation. It reads from and writes to TrendMines's API. The **web dashboard** is where the human operator reviews signals, evaluates niches, reviews AI-generated designs, and monitors business performance. **Production decisions (what to print, how many printers to allocate, Etsy listing creation, Printify fulfillment) remain human-driven and are handled outside the platform.**

---

## Reference Documents

Read these documents in order. Each builds on the previous one.

### 1. `product-discovery-process.md`
**What it covers:** The core business process — how to find trending products, evaluate them, test them on Etsy, and manage their lifecycle. This is the "why" behind every feature.

**Key concepts to internalize:**
- The 6-step process: Signal Scanning → Candidate Filtering → Prototyping → Listing Test → Scale → Decay Monitoring
- The candidate scorecard (cultural momentum, emotional intensity, printability, giftability, margin, saturation) with weighted scoring
- The decision framework for scaling vs. ignoring listings (no "killing" — dead listings stay up, they cost nothing)
- AO3 fanfiction tag growth as the #1 leading indicator for fandom purchasing behavior

**Relevant to:** Every feature. This document is the business logic specification.

### 2. `niche-discovery-product-generation.md`
**What it covers:** How to find passionate niche communities and extract specific product ideas from them without being a member of the community.

**Key concepts to internalize:**
- The demand/supply ratio metric (AO3 activity ÷ Etsy listing count)
- Cultural token taxonomy: quotes, symbols, ship names, character pairings, running jokes, color associations
- The source-by-source extraction guide (wiki, Tumblr, Reddit, AO3, Etsy reviews, TikTok) — each with specific API references
- The ranking criteria for tokens: frequency, emotional intensity, visual potential, uniqueness, Etsy gap, printability

**Relevant to:** Niche Pipeline, Cultural Token Explorer, and the data model for signals/niches/tokens.

### 3. `openclaw-automation.md`
**What it covers:** Which parts of the process OpenClaw automates and how it delivers information to the operator.

**Key concepts to internalize:**
- The automation map: fully automatable (signal scanning, decay monitoring), semi-automatable (candidate filtering, listing monitoring), human-required (prototyping, scale decisions)
- The cron schedule and scanning frequency for each data source
- The daily digest and weekly candidate brief formats — these define what the dashboard's Signal Radar needs to display
- The alert format for traction signals and decay warnings

**Relevant to:** API design (what OpenClaw writes and reads), webhook design, alert system.

### 4. `api-reference.md`
**What it covers:** Every external API and data source the system integrates with, including auth methods, rate limits, Python/JS libraries, costs, and what data each provides.

**Key concepts to internalize:**
- Tier 1 (free): Reddit/PRAW, Tumblr API v2, AO3 unofficial Python API, Fandom Stats API, Etsy Open API v3
- Tier 2 (freemium): Google Trends API (alpha), eRank, Marmalead
- Tier 3 (paid): Apify, ScrapeCreators, Data365
- The recommended implementation order: AO3 + Reddit first, then Tumblr + Google Trends, then Etsy, then TikTok
- Rate limits and auth methods for each

**Relevant to:** Settings page (API key management), background job design (rate limiting), OpenClaw skill configuration.

### 5. `nano-banana-automation.md`
**What it covers:** How to use Google's Gemini image generation (Nano Banana / Nano Banana Pro) to automatically create product designs and listing photos.

**Key concepts to internalize:**
- What it can automate per product type: t-shirts (nearly fully), magnets (concept art only — 3D modeling is still manual), listing photos (fully)
- The prompt template system for different product/photo types
- The batch generation flow: cultural tokens → prompt templates → Gemini API → design review gallery
- The cost model (~$0.039/image, ~$10-15/month total)
- The print-on-demand t-shirt opportunity via Printify (zero inventory, auto-fulfillment)

**Relevant to:** Design Review Gallery, prompt template settings, Gemini API integration, Printify integration.

### 6. `trendforge-system-design.md`
**What it covers:** The complete system design — architecture, data model, all 10 dashboard features with detailed specifications, API endpoint definitions, tech stack recommendation, and MVP phasing.

**This is your primary implementation reference.** It contains:
- Architecture diagram (data sources → OpenClaw → TrendMines API/DB → Dashboard → outputs)
- Full entity-relationship data model (Signal, Niche, CulturalToken, Design, Product, Listing, MetricSnapshot, PrinterAssignment)
- 10 feature specifications with UI descriptions and API endpoints
- REST API conventions (auth, pagination, CRUD patterns, webhooks)
- OpenClaw skill ↔ API endpoint mapping
- Tech stack: Rails, PostgreSQL, Sidekiq, Hotwire/React, S3/R2, Redis
- 4-phase MVP roadmap

**Relevant to:** Everything. This is the implementation spec.

---

## Tech Stack

- **Backend:** Ruby on Rails (API mode + views)
- **Database:** PostgreSQL (use JSONB columns for flexible data: `raw_data` on signals, `source_references` on tokens)
- **Background jobs:** Sidekiq + Redis
- **Frontend:** Hotwire (Turbo + Stimulus) for most views. Consider React for the Design Review Gallery (keyboard-driven image review) and Niche Pipeline kanban (drag-and-drop).
- **File storage:** S3-compatible (Cloudflare R2 or AWS S3) for generated design images
- **External integrations:** Gemini API (Nano Banana) for design generation. Etsy API v3 for metrics/monitoring only (listing creation is manual).
- **Auth:** API key auth for OpenClaw, Devise or similar for dashboard login

---

## How to Create Tickets

Break the work into the 4 phases defined in `trendforge-system-design.md`. Within each phase, create tickets at these granularities:

### Phase 1 — Foundation

**Infrastructure tickets:**
- [ ] Rails project setup (API mode + Hotwire, PostgreSQL, Sidekiq, Redis)
- [ ] Database schema migration for all entities (Signal, Niche, CulturalToken, Design, Product, Listing, MetricSnapshot)
- [ ] Model layer with associations, validations, and scopes
- [ ] API authentication (API key for OpenClaw, session/JWT for dashboard)
- [ ] Base API controller with pagination, filtering, sorting conventions
- [ ] S3/R2 file storage configuration (ActiveStorage)
- [ ] Seed data for development (sample signals, niches, tokens)

**API resource tickets (one per resource):**
- [ ] Signals API — full CRUD + `/history` endpoint + status transitions
- [ ] Niches API — full CRUD + `/tokens`, `/designs`, `/scorecard` nested endpoints + stage transitions
- [ ] Cultural Tokens API — full CRUD + `/sources` + `/generate` action
- [ ] Designs API — full CRUD + `/regenerate` action + image serving
- [ ] Products API — full CRUD + `/listings`, `/metrics` nested (read-only tracking, no auto-listing)
- [ ] Listings API — full CRUD + `/metrics` nested + `/alerts` + `/leaderboard`
- [ ] Settings API — read/update config + API key management + `/test-connection`
- [ ] Webhooks — outbound webhook delivery to OpenClaw

**Dashboard tickets:**
- [ ] Application layout (nav, sidebar, responsive shell)
- [ ] Signal Radar view (live feed, sparklines, filters, "Promote to Niche" action)
- [ ] Niche Pipeline view (kanban board with drag-and-drop stage transitions)
- [ ] Basic Settings page (API keys, scan frequencies, alert thresholds)

### Phase 2 — Intelligence

- [ ] Cultural Token Explorer (sortable table, filters, inline score breakdown, bulk actions)
- [ ] Listing Performance Dashboard (summary stats, listing table with traction badges, daily charts)
- [ ] Decay Monitor (lifecycle stage indicators, per-product charts, alerts, recommended actions)
- [ ] Analytics — Revenue dashboard (daily/weekly/monthly, by product type)
- [ ] Analytics — Pipeline funnel (signals → niches → tokens → designs → products → listings → sales)
- [ ] Analytics — Source ROI (which data source produces the most revenue)
- [ ] MetricSnapshot collection job (Sidekiq job to snapshot listing metrics on schedule)

### Phase 3 — Automation

- [ ] Design Review Gallery (image grid, keyboard navigation, approve/reject, side-by-side comparison)
- [ ] Gemini API integration (service object for Nano Banana image generation)
- [ ] Prompt Template management (CRUD in settings, variable interpolation: `{QUOTE}`, `{FANDOM}`, `{COLORS}`)
- [ ] Design generation pipeline (token → prompt → Gemini API → save image → create Design record)
- [ ] Webhook integration for OpenClaw notifications
- [ ] Alert notification system (configurable thresholds, delivery via webhook to OpenClaw)

> **Out of scope (handled externally by operator):** Printify integration, auto-listing creation on Etsy, printer fleet management, capacity planning, production queue management. TrendMines generates insights and design candidates — the operator handles production and fulfillment.

---

## Coding Standards

- **Follow SOLID principles.** Keep classes and files concise. Single responsibility per class.
- **Document everything** with YARD (Ruby) or JSDoc (JavaScript). Every public method, every API endpoint.
- **Write tests.** RSpec for Rails (model specs, request specs for every API endpoint). System tests for critical dashboard flows.
- **Use service objects** for business logic (e.g., `Signals::PromoteToNiche`, `Designs::GenerateFromToken`, `Listings::ClassifyTraction`). Keep controllers thin.
- **Use form objects or strong params** for API input validation.
- **Background jobs** for anything that calls external APIs (Gemini, data source scanning). Never block the request cycle on external calls.
- **JSONB columns** for flexible/evolving data (`raw_data`, `source_references`, `prompt_config`). Use typed accessors (e.g., `store_accessor`) for frequently queried fields.
- **Enum-based status fields** with state machine transitions (consider `aasm` or `statesman` gems).
- **API versioning** from the start: `/api/v1/...` — this API will evolve.

---

## Key Business Rules to Encode

These come from the process documents and should be implemented as domain logic:

1. **Demand/supply ratio** = (AO3 works count × growth rate + Reddit engagement + Tumblr engagement) ÷ Etsy listing count. Threshold for "priority niche": ratio > X (configurable in settings).

2. **Candidate scorecard** is a weighted formula. Weights are configurable in settings. See `product-discovery-process.md` for the full scorecard (max score 26, prototype threshold 18+).

3. **Listing traction classification:**
   - 🔥 Scaling: any organic sale within 14 days
   - 📊 Promising: fav/view > 5%, no sale yet
   - 😐 No signal: views > 100, fav/view < 5%, no sale
   - No action needed for listings with low views — could be SEO, leave them up

4. **Decay detection triggers** (all configurable):
   - Two consecutive weeks of sales decline
   - Google Trends keyword dropped 30%+ from peak
   - Competitor listing count doubled from baseline

5. **Listings are never deleted.** They cost $0.20 to create and have no ongoing cost. Dead listings stay up indefinitely.

7. **Design generation cost tracking:** Every Gemini API call logs its cost ($0.039/image). Aggregate in analytics.

---

## Getting Started

1. Read all 6 reference documents.
2. Set up the Rails project with PostgreSQL + Sidekiq + Redis.
3. Create the database migration for all entities from the ER diagram in `trendforge-system-design.md`.
4. Build the model layer with associations and validations.
5. Scaffold the API controllers with the pagination/filtering conventions.
6. Build the Signal Radar as the first dashboard view — this proves the full stack works end-to-end.
7. Then proceed through the ticket list in phase order.

Good luck. Build something great.
