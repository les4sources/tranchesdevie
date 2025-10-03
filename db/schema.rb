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

ActiveRecord::Schema[8.0].define(version: 2025_10_03_211842) do
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

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.string "unit", default: "g", comment: "Default unit: g (grams), kg, L, ml, units"
    t.boolean "is_allergen", default: false, null: false
    t.string "allergen_type", comment: "gluten, dairy, nuts, eggs, etc."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_allergen"], name: "index_ingredients_on_is_allergen"
    t.index ["name"], name: "index_ingredients_on_name", unique: true
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

  create_table "product_availabilities", force: :cascade do |t|
    t.bigint "product_variant_id", null: false
    t.date "available_from"
    t.date "available_until"
    t.string "days_of_week", comment: "Comma-separated day numbers (2=Tuesday, 5=Friday)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_until"], name: "index_product_availabilities_on_available_until"
    t.index ["product_variant_id", "available_from"], name: "idx_on_product_variant_id_available_from_87ead5d25c"
    t.index ["product_variant_id"], name: "index_product_availabilities_on_product_variant_id"
  end

  create_table "product_ingredients", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "unit", comment: "Unit for this quantity (inherits from ingredient if not specified)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_product_ingredients_on_ingredient_id"
    t.index ["product_id", "ingredient_id"], name: "idx_product_ingredients_unique", unique: true
    t.index ["product_id"], name: "index_product_ingredients_on_product_id"
  end

  create_table "product_variants", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "name", null: false
    t.integer "weight_grams"
    t.integer "price_cents", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_product_variants_on_active"
    t.index ["product_id", "name"], name: "index_product_variants_on_product_id_and_name", unique: true
    t.index ["product_id"], name: "index_product_variants_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category"], name: "index_products_on_category"
    t.index ["name"], name: "index_products_on_name"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  add_foreign_key "phone_verifications", "customers"
  add_foreign_key "product_availabilities", "product_variants"
  add_foreign_key "product_ingredients", "ingredients"
  add_foreign_key "product_ingredients", "products"
  add_foreign_key "product_variants", "products"
end
