class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :key, null: false, index: { unique: true }
      t.json :value
      t.string :category, null: false
      t.text :description
      t.timestamps
    end

    add_index :settings, :category
  end
end
