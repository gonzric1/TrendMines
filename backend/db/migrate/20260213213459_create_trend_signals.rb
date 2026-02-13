class CreateTrendSignals < ActiveRecord::Migration[8.1]
  def change
    create_table :trend_signals do |t|
      t.string :source
      t.string :topic
      t.text :description
      t.float :momentum_score
      t.json :raw_data
      t.string :status
      t.datetime :first_seen
      t.datetime :last_updated

      t.timestamps
    end
  end
end
