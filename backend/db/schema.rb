# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_14_202227) do
  create_table "cultural_tokens", force: :cascade do |t|
    t.float "composite_score"
    t.datetime "created_at", null: false
    t.float "emotional_intensity"
    t.float "frequency_score"
    t.integer "niche_id", null: false
    t.json "source_references"
    t.string "status"
    t.string "token_type"
    t.float "uniqueness_score"
    t.datetime "updated_at", null: false
    t.string "value"
    t.float "visual_potential"
    t.index ["niche_id"], name: "index_cultural_tokens_on_niche_id"
  end

  create_table "designs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "cultural_token_id", null: false
    t.string "design_type"
    t.decimal "generation_cost"
    t.string "image_url"
    t.text "prompt_used"
    t.string "status"
    t.string "style"
    t.datetime "updated_at", null: false
    t.index ["cultural_token_id"], name: "index_designs_on_cultural_token_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "listings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "etsy_listing_id"
    t.datetime "listed_at"
    t.decimal "price"
    t.integer "product_id", null: false
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_listings_on_product_id"
  end

  create_table "metric_snapshots", force: :cascade do |t|
    t.datetime "captured_at"
    t.datetime "created_at", null: false
    t.float "fav_view_ratio"
    t.integer "favorites"
    t.integer "listing_id", null: false
    t.decimal "revenue"
    t.integer "sales"
    t.datetime "updated_at", null: false
    t.integer "views"
    t.index ["listing_id"], name: "index_metric_snapshots_on_listing_id"
  end

  create_table "niches", force: :cascade do |t|
    t.float "ao3_growth_rate"
    t.integer "ao3_works_count"
    t.string "community_type"
    t.datetime "created_at", null: false
    t.float "demand_score"
    t.float "demand_supply_ratio"
    t.text "description"
    t.datetime "discovered_at"
    t.integer "etsy_listing_count"
    t.string "name"
    t.string "status"
    t.float "supply_score"
    t.integer "trend_signal_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trend_signal_id"], name: "index_niches_on_trend_signal_id"
  end

  create_table "printer_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "printer_name"
    t.integer "product_id", null: false
    t.string "status"
    t.integer "units_allocated"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_printer_assignments_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "design_id", null: false
    t.float "margin_pct"
    t.string "name"
    t.integer "print_time_minutes"
    t.string "product_type"
    t.string "status"
    t.string "stl_file_url"
    t.decimal "target_price"
    t.decimal "unit_cost"
    t.integer "units_per_batch"
    t.datetime "updated_at", null: false
    t.index ["design_id"], name: "index_products_on_design_id"
  end

  create_table "trend_signals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "first_seen"
    t.datetime "last_updated"
    t.float "momentum_score"
    t.json "raw_data"
    t.string "source"
    t.string "status"
    t.string "topic"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cultural_tokens", "niches"
  add_foreign_key "designs", "cultural_tokens"
  add_foreign_key "listings", "products"
  add_foreign_key "metric_snapshots", "listings"
  add_foreign_key "niches", "trend_signals"
  add_foreign_key "printer_assignments", "products"
  add_foreign_key "products", "designs"
end
