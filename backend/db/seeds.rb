# Clear existing data
puts "Clearing existing data..."
Setting.destroy_all
PrinterAssignment.destroy_all
MetricSnapshot.destroy_all
Listing.destroy_all
Product.destroy_all
Design.destroy_all
CulturalToken.destroy_all
Niche.destroy_all
TrendSignal.destroy_all

# Create Trend Signals
puts "Creating trend signals..."
signal1 = TrendSignal.create!(
  source: "AO3",
  topic: "Good Omens Season 3 Renewal",
  description: "Massive spike in Good Omens fanfiction after renewal announcement",
  momentum_score: 8.5,
  status: "watching",
  first_seen: 1.week.ago,
  last_updated: Time.current,
  raw_data: {
    ao3_works: 45000,
    growth_rate: 0.15,
    trending_tags: ["Ineffable Husbands", "Crowley/Aziraphale", "Post-Season 2"]
  }
)

signal2 = TrendSignal.create!(
  source: "Reddit",
  topic: "Palestine Solidarity Movement",
  description: "High engagement on Palestine solidarity content",
  momentum_score: 7.2,
  status: "promoted",
  first_seen: 2.weeks.ago,
  last_updated: Time.current,
  raw_data: {
    subreddits: ["r/Palestine", "r/activism"],
    upvotes_trend: "increasing"
  }
)

# Create Niches
puts "Creating niches..."
niche1 = Niche.create!(
  trend_signal: signal1,
  name: "Good Omens Fandom",
  description: "Passionate fandom around Good Omens series, high demand for Ineffable Husbands merch",
  community_type: "fandom",
  demand_score: 9.0,
  supply_score: 3.5,
  demand_supply_ratio: 2.57,
  ao3_works_count: 45000,
  ao3_growth_rate: 0.15,
  etsy_listing_count: 850,
  status: "mining_tokens",
  discovered_at: 1.week.ago
)

# Create Cultural Tokens
puts "Creating cultural tokens..."
token1 = CulturalToken.create!(
  niche: niche1,
  token_type: "quote",
  value: "To the world",
  frequency_score: 8.5,
  emotional_intensity: 9.0,
  visual_potential: 7.5,
  uniqueness_score: 8.0,
  composite_score: 8.25,
  status: "designs_pending",
  source_references: {
    ao3_tags: ["Ineffable Husbands", "to the world"],
    tumblr_posts: 1250
  }
)

# Create Designs
puts "Creating designs..."
design1 = Design.create!(
  cultural_token: token1,
  prompt_used: "Create a minimalist magnet design featuring 'To the world' in elegant script",
  design_type: "magnet",
  style: "minimalist",
  status: "approved",
  generation_cost: 0.039
)

# Create Products
puts "Creating products..."
product1 = Product.create!(
  design: design1,
  product_type: "fridge_magnet",
  name: "Good Omens 'To the World' Magnet",
  unit_cost: 0.75,
  target_price: 4.99,
  margin_pct: 85.0,
  print_time_minutes: 45,
  units_per_batch: 6,
  status: "listed"
)

# Create Listings
puts "Creating listings..."
listing1 = Listing.create!(
  product: product1,
  etsy_listing_id: "1234567890",
  title: "Good Omens To The World Fridge Magnet - Ineffable Husbands Fan Gift",
  status: "active",
  price: 4.99,
  listed_at: 14.days.ago
)

# Create Metric Snapshots
puts "Creating metric snapshots..."
14.downto(0) do |days_ago|
  base_views = 50 + (14 - days_ago) * 5
  MetricSnapshot.create!(
    listing: listing1,
    views: base_views,
    favorites: (base_views * 0.08).to_i,
    sales: days_ago < 7 ? 1 : 0,
    fav_view_ratio: 0.08,
    revenue: days_ago < 7 ? 4.99 : 0,
    captured_at: days_ago.days.ago
  )
end

# Create Printer Assignments
puts "Creating printer assignments..."
PrinterAssignment.create!(
  product: product1,
  printer_name: "Ender 3 Pro #1",
  units_allocated: 12,
  status: :active
)

# Create Settings
puts "Creating settings..."
[
  # Scanning frequencies (hours between scans)
  { key: "scanning.ao3_frequency", value: 12, category: "scanning", description: "Hours between AO3 scans" },
  { key: "scanning.reddit_frequency", value: 6, category: "scanning", description: "Hours between Reddit scans" },
  { key: "scanning.etsy_frequency", value: 24, category: "scanning", description: "Hours between Etsy scans" },
  { key: "scanning.tumblr_frequency", value: 12, category: "scanning", description: "Hours between Tumblr scans" },
  # Scoring weights (1-10)
  { key: "scoring.momentum_weight", value: 3, category: "scoring", description: "Weight for momentum score (1-10)" },
  { key: "scoring.demand_supply_weight", value: 5, category: "scoring", description: "Weight for demand/supply ratio (1-10)" },
  { key: "scoring.frequency_weight", value: 4, category: "scoring", description: "Weight for frequency score (1-10)" },
  { key: "scoring.emotional_weight", value: 3, category: "scoring", description: "Weight for emotional intensity (1-10)" },
  { key: "scoring.visual_weight", value: 4, category: "scoring", description: "Weight for visual potential (1-10)" },
  { key: "scoring.uniqueness_weight", value: 5, category: "scoring", description: "Weight for uniqueness score (1-10)" },
  { key: "scoring.viability_threshold", value: 0.6, category: "scoring", description: "Minimum viability score to promote a niche (0-1)" },
  # Alert thresholds
  { key: "alerts.sales_drop_threshold", value: 0.3, category: "alerts", description: "Sales drop ratio that triggers an alert (0-1)" },
  { key: "alerts.low_fav_view_ratio", value: 0.02, category: "alerts", description: "Minimum fav/view ratio before alerting (0-1)" },
  { key: "alerts.min_daily_views", value: 10, category: "alerts", description: "Minimum daily views before alerting" },
  # Integrations
  { key: "integrations.webhook_url", value: "", category: "integrations", description: "Webhook URL for notifications" },
].each do |attrs|
  Setting.create!(attrs)
end

puts "\nSeed data created successfully!"
puts "  - Settings: #{Setting.count}"
puts "  - Trend Signals: #{TrendSignal.count}"
puts "  - Niches: #{Niche.count}"
puts "  - Cultural Tokens: #{CulturalToken.count}"
puts "  - Designs: #{Design.count}"
puts "  - Products: #{Product.count}"
puts "  - Listings: #{Listing.count}"
puts "  - Metric Snapshots: #{MetricSnapshot.count}"
puts "  - Printer Assignments: #{PrinterAssignment.count}"
