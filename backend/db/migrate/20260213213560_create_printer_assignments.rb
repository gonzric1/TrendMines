class CreatePrinterAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :printer_assignments do |t|
      t.references :product, null: false, foreign_key: true
      t.string :printer_name
      t.integer :units_allocated
      t.string :status

      t.timestamps
    end
  end
end
