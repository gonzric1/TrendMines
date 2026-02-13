class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.references :product, null: false, foreign_key: true
      t.string :etsy_listing_id
      t.string :title
      t.string :status
      t.decimal :price
      t.datetime :listed_at

      t.timestamps
    end
  end
end
