class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.string :category

      t.timestamps
    end
    
    add_index :products, :name
    add_index :products, :active
    add_index :products, :category
  end
end
