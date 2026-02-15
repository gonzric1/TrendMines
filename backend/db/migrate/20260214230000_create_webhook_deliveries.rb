class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.string :event_type, null: false
      t.json :payload, null: false
      t.string :url, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :last_attempt_at
      t.integer :response_code
      t.text :response_body
      t.timestamps
    end
    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :event_type
  end
end
