class AddLockVersionToProductionCaps < ActiveRecord::Migration[8.0]
  def change
    add_column :production_caps, :lock_version, :integer, null: false, default: 0, 
               comment: "Optimistic locking version for handling concurrent updates"
  end
end
