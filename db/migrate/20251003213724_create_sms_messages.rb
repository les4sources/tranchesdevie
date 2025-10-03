class CreateSmsMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :sms_messages do |t|
      t.references :customer, null: true, foreign_key: true
      t.string :phone_e164, null: false
      t.text :message_body, null: false
      t.string :direction, null: false, comment: "outbound, inbound"
      t.string :status, default: "pending", null: false, comment: "pending, sent, delivered, failed"
      t.datetime :sent_at
      t.string :telerivet_message_id
      t.text :error_message

      t.timestamps
    end
    
    add_index :sms_messages, :phone_e164
    add_index :sms_messages, :status
    add_index :sms_messages, :sent_at
    add_index :sms_messages, :telerivet_message_id, unique: true
    add_index :sms_messages, [:customer_id, :created_at]
  end
end
