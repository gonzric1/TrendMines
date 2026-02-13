class CreateDesigns < ActiveRecord::Migration[8.1]
  def change
    create_table :designs do |t|
      t.references :cultural_token, null: false, foreign_key: true
      t.text :prompt_used
      t.string :image_url
      t.string :design_type
      t.string :style
      t.string :status
      t.decimal :generation_cost

      t.timestamps
    end
  end
end
