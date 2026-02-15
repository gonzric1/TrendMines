class AddCorrelatedSignalIdToTrendSignals < ActiveRecord::Migration[8.1]
  def change
    add_column :trend_signals, :correlated_signal_id, :integer
    add_index :trend_signals, :correlated_signal_id
    add_foreign_key :trend_signals, :trend_signals, column: :correlated_signal_id
  end
end
