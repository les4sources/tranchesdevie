class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false

      t.timestamps
    end
    
    add_index :order_items, [:order_id, :product_variant_id], unique: true, name: 'idx_order_items_unique'
  end
end
