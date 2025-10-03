class CreateProductAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :product_availabilities do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.date :available_from
      t.date :available_until
      t.string :days_of_week, comment: "Comma-separated day numbers (2=Tuesday, 5=Friday)"

      t.timestamps
    end
    
    add_index :product_availabilities, [:product_variant_id, :available_from]
    add_index :product_availabilities, :available_until
  end
end
