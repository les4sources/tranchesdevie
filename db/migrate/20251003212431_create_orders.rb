class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :bake_day, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :status, default: "pending", null: false
      t.integer :total_cents, null: false, default: 0
      t.string :pickup_location
      t.datetime :ready_at
      t.datetime :picked_up_at
      t.boolean :is_standing_order, default: false, null: false

      t.timestamps
    end
    
    add_index :orders, :order_number, unique: true
    # Composite index as specified in PRD
    add_index :orders, [:bake_day_id, :status], name: 'idx_orders_bake_day_status'
    add_index :orders, :status
  end
end
