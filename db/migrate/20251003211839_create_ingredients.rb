class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false
      t.string :unit, default: "g", comment: "Default unit: g (grams), kg, L, ml, units"
      t.boolean :is_allergen, default: false, null: false
      t.string :allergen_type, comment: "gluten, dairy, nuts, eggs, etc."

      t.timestamps
    end
    
    add_index :ingredients, :name, unique: true
    add_index :ingredients, :is_allergen
  end
end
