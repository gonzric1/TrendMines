class CreateCulturalTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :cultural_tokens do |t|
      t.references :niche, null: false, foreign_key: true
      t.string :token_type
      t.string :value
      t.float :frequency_score
      t.float :emotional_intensity
      t.float :visual_potential
      t.float :uniqueness_score
      t.float :composite_score
      t.json :source_references
      t.string :status

      t.timestamps
    end
  end
end
