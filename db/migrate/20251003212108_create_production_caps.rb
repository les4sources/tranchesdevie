class CreateProductionCaps < ActiveRecord::Migration[8.0]
  def change
    create_table :production_caps do |t|
      t.references :bake_day, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :capacity, null: false, default: 0, comment: "Maximum units that can be produced"
      t.integer :reserved, null: false, default: 0, comment: "Units already reserved by orders"

      t.timestamps
    end
    
    # Composite index as specified in PRD
    add_index :production_caps, [:bake_day_id, :product_variant_id], 
              unique: true, 
              name: 'idx_production_caps_bake_variant'
  end
end
