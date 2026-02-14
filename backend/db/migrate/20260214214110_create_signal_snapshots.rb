class CreateSignalSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :signal_snapshots do |t|
      t.references :trend_signal, null: false, foreign_key: true
      t.float :momentum_score
      t.json :source_metrics
      t.datetime :captured_at

      t.timestamps
    end

    add_index :signal_snapshots, [:trend_signal_id, :captured_at]
  end
end
