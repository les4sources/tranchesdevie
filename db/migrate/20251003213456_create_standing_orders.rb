class CreateStandingOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :standing_orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :frequency, null: false, comment: "tuesday, friday, both"
      t.string :status, default: "active", null: false, comment: "active, paused, cancelled"
      t.date :next_bake_date

      t.timestamps
    end
    
    add_index :standing_orders, :status
    add_index :standing_orders, :next_bake_date
    add_index :standing_orders, [:customer_id, :status]
  end
end
