class CreateStandingOrderSkips < ActiveRecord::Migration[8.0]
  def change
    create_table :standing_order_skips do |t|
      t.references :standing_order, null: false, foreign_key: true
      t.date :skipped_date, null: false
      t.string :reason, comment: "pause, stop, manual"

      t.timestamps
    end
    
    add_index :standing_order_skips, [:standing_order_id, :skipped_date], 
              unique: true, 
              name: 'idx_standing_order_skips_unique'
    add_index :standing_order_skips, :skipped_date
  end
end
