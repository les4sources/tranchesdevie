class CreateProductIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :product_ingredients do |t|
      t.references :product, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :unit, comment: "Unit for this quantity (inherits from ingredient if not specified)"

      t.timestamps
    end
    
    add_index :product_ingredients, [:product_id, :ingredient_id], unique: true, name: 'idx_product_ingredients_unique'
  end
end
