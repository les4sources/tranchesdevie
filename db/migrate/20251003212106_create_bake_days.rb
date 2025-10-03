class CreateBakeDays < ActiveRecord::Migration[8.0]
  def change
    create_table :bake_days do |t|
      t.date :baked_on, null: false, comment: "The date of the bake"
      t.integer :day_of_week, null: false, comment: "0=Sunday, 1=Monday, 2=Tuesday, 5=Friday, etc."
      t.datetime :cut_off_at, null: false, comment: "Deadline for orders (timezone-aware)"
      t.string :status, default: "open", null: false, comment: "open, locked, completed"

      t.timestamps
    end
    
    add_index :bake_days, :baked_on, unique: true
    add_index :bake_days, :status
    add_index :bake_days, :cut_off_at
  end
end
