class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :email
      t.string :phone_e164, null: false

      t.timestamps
    end
    
    add_index :customers, :phone_e164, unique: true
    add_index :customers, :email
  end
end
