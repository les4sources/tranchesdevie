class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.integer :amount_cents, null: false
      t.string :payment_method, comment: "card, bancontact, apple_pay, google_pay"
      t.string :status, default: "pending", null: false
      t.string :stripe_payment_intent_id
      t.string :stripe_charge_id
      t.datetime :processed_at
      t.text :error_message
      t.string :refund_id
      t.datetime :refunded_at

      t.timestamps
    end
    
    add_index :payments, :stripe_payment_intent_id, unique: true
    add_index :payments, :stripe_charge_id
    add_index :payments, :status
  end
end
