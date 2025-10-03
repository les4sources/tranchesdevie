# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_03_211135) do
  create_schema "test"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name"
    t.string "email"
    t.string "phone_e164", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email"
    t.index ["phone_e164"], name: "index_customers_on_phone_e164", unique: true
  end

  create_table "phone_verifications", force: :cascade do |t|
    t.string "phone_e164", null: false
    t.string "verification_code", null: false
    t.datetime "expires_at", null: false
    t.datetime "verified_at"
    t.bigint "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_phone_verifications_on_customer_id"
    t.index ["expires_at"], name: "index_phone_verifications_on_expires_at"
    t.index ["phone_e164", "verification_code"], name: "index_phone_verifications_on_phone_e164_and_verification_code"
    t.index ["phone_e164"], name: "index_phone_verifications_on_phone_e164"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  add_foreign_key "phone_verifications", "customers"
end
