class CreateAdminPages < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.boolean :published, default: false, null: false
      t.string :locale, default: "fr", null: false, comment: "fr, nl, en"

      t.timestamps
    end
    
    add_index :admin_pages, :slug, unique: true
    add_index :admin_pages, [:locale, :published]
  end
end
