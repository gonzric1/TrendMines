class CreateMetricSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :metric_snapshots do |t|
      t.references :listing, null: false, foreign_key: true
      t.integer :views
      t.integer :favorites
      t.integer :sales
      t.float :fav_view_ratio
      t.decimal :revenue
      t.datetime :captured_at

      t.timestamps
    end
  end
end
