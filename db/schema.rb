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

ActiveRecord::Schema[8.0].define(version: 2025_10_03_213241) do
  create_schema "test"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bake_days", force: :cascade do |t|
    t.date "baked_on", null: false, comment: "The date of the bake"
    t.integer "day_of_week", null: false, comment: "0=Sunday, 1=Monday, 2=Tuesday, 5=Friday, etc."
    t.datetime "cut_off_at", null: false, comment: "Deadline for orders (timezone-aware)"
    t.string "status", default: "open", null: false, comment: "open, locked, completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baked_on"], name: "index_bake_days_on_baked_on", unique: true
    t.index ["cut_off_at"], name: "index_bake_days_on_cut_off_at"
    t.index ["status"], name: "index_bake_days_on_status"
  end

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

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_variant_id"], name: "idx_order_items_unique", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "bake_day_id", null: false
    t.string "order_number", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "pickup_location"
    t.datetime "ready_at"
    t.datetime "picked_up_at"
    t.boolean "is_standing_order", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bake_day_id", "status"], name: "idx_orders_bake_day_status"
    t.index ["bake_day_id"], name: "index_orders_on_bake_day_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.integer "amount_cents", null: false
    t.string "payment_method", comment: "card, bancontact, apple_pay, google_pay"
    t.string "status", default: "pending", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_charge_id"
    t.datetime "processed_at"
    t.text "error_message"
    t.string "refund_id"
    t.datetime "refunded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
    t.index ["status"], name: "index_payments_on_status"
    t.index ["stripe_charge_id"], name: "index_payments_on_stripe_charge_id"
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
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

  create_table "production_caps", force: :cascade do |t|
    t.bigint "bake_day_id", null: false
    t.bigint "product_variant_id", null: false
    t.integer "capacity", default: 0, null: false, comment: "Maximum units that can be produced"
    t.integer "reserved", default: 0, null: false, comment: "Units already reserved by orders"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bake_day_id", "product_variant_id"], name: "idx_production_caps_bake_variant", unique: true
    t.index ["bake_day_id"], name: "index_production_caps_on_bake_day_id"
    t.index ["product_variant_id"], name: "index_production_caps_on_product_variant_id"
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

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "orders", "bake_days"
  add_foreign_key "orders", "customers"
  add_foreign_key "payments", "orders"
  add_foreign_key "phone_verifications", "customers"
  add_foreign_key "product_availabilities", "product_variants"
  add_foreign_key "product_ingredients", "ingredients"
  add_foreign_key "product_ingredients", "products"
  add_foreign_key "product_variants", "products"
  add_foreign_key "production_caps", "bake_days"
  add_foreign_key "production_caps", "product_variants"
end
