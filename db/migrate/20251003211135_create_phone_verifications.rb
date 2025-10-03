class CreatePhoneVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :phone_verifications do |t|
      t.string :phone_e164, null: false
      t.string :verification_code, null: false
      t.datetime :expires_at, null: false
      t.datetime :verified_at
      t.references :customer, null: true, foreign_key: true

      t.timestamps
    end
    
    add_index :phone_verifications, :phone_e164
    add_index :phone_verifications, [:phone_e164, :verification_code]
    add_index :phone_verifications, :expires_at
  end
end
