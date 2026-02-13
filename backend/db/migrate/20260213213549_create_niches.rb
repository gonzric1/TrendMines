class CreateNiches < ActiveRecord::Migration[8.1]
  def change
    create_table :niches do |t|
      t.string :name
      t.text :description
      t.string :community_type
      t.float :demand_score
      t.float :supply_score
      t.float :demand_supply_ratio
      t.integer :ao3_works_count
      t.float :ao3_growth_rate
      t.integer :etsy_listing_count
      t.string :status
      t.datetime :discovered_at
      t.references :trend_signal, null: false, foreign_key: true

      t.timestamps
    end
  end
end
