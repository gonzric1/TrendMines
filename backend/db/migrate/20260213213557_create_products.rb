class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :design, null: false, foreign_key: true
      t.string :product_type
      t.string :name
      t.decimal :unit_cost
      t.decimal :target_price
      t.float :margin_pct
      t.integer :print_time_minutes
      t.integer :units_per_batch
      t.string :stl_file_url
      t.string :status

      t.timestamps
    end
  end
end
