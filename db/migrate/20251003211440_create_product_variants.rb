class CreateProductVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :weight_grams
      t.integer :price_cents, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :product_variants, [:product_id, :name], unique: true
    add_index :product_variants, :active
  end
end
