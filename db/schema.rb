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

ActiveRecord::Schema[8.0].define(version: 2025_07_11_051411) do
  create_table "transactions", force: :cascade do |t|
    t.datetime "transaction_datetime", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "description", null: false
    t.string "category", default: "Uncategorized"
    t.string "transaction_type"
    t.string "account_name"
    t.string "reference_number", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_transactions_on_category"
    t.index ["reference_number"], name: "index_transactions_on_reference_number_unique", unique: true
    t.index ["transaction_datetime", "transaction_type"], name: "idx_on_transaction_datetime_transaction_type_be325984ca"
    t.index ["transaction_datetime"], name: "index_transactions_on_transaction_datetime"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end
end
