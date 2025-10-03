class CreateStandingOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :standing_order_items do |t|
      t.references :standing_order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
    
    add_index :standing_order_items, [:standing_order_id, :product_variant_id], 
              unique: true, 
              name: 'idx_standing_order_items_unique'
  end
end
