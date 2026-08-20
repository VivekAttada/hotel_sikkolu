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

ActiveRecord::Schema[8.1].define(version: 2026_08_20_160000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bill_line_items", force: :cascade do |t|
    t.integer "bill_id", null: false
    t.datetime "created_at", null: false
    t.string "item_name", null: false
    t.decimal "line_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "menu_item_id"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_line_items_on_bill_id"
    t.index ["menu_item_id"], name: "index_bill_line_items_on_menu_item_id"
  end

  create_table "bills", force: :cascade do |t|
    t.string "bill_number", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "dining_table_id", null: false
    t.datetime "opened_at", null: false
    t.datetime "paid_at"
    t.string "status", default: "active", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_number"], name: "index_bills_on_bill_number", unique: true
    t.index ["deleted_at"], name: "index_bills_on_deleted_at"
    t.index ["dining_table_id", "status"], name: "index_bills_on_dining_table_id_and_status"
    t.index ["dining_table_id"], name: "index_bills_on_dining_table_id"
    t.index ["paid_at"], name: "index_bills_on_paid_at"
    t.index ["status"], name: "index_bills_on_status"
  end

  create_table "checklist_entries", force: :cascade do |t|
    t.boolean "checked", default: false, null: false
    t.datetime "checked_at"
    t.integer "checklist_task_id", null: false
    t.datetime "created_at", null: false
    t.integer "daily_checklist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_task_id"], name: "index_checklist_entries_on_checklist_task_id"
    t.index ["daily_checklist_id", "checklist_task_id"], name: "index_checklist_entries_on_daily_and_task", unique: true
    t.index ["daily_checklist_id"], name: "index_checklist_entries_on_daily_checklist_id"
  end

  create_table "checklist_tasks", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "frequency", default: "daily", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["frequency"], name: "index_checklist_tasks_on_frequency"
    t.index ["position"], name: "index_checklist_tasks_on_position"
  end

  create_table "daily_checklists", force: :cascade do |t|
    t.date "checklist_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_date"], name: "index_daily_checklists_on_checklist_date", unique: true
  end

  create_table "daily_inventories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "inventory_date", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["inventory_date"], name: "index_daily_inventories_on_inventory_date", unique: true
  end

  create_table "dining_tables", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dining_tables_on_name", unique: true
  end

  create_table "grocery_items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "imported_at", null: false
    t.decimal "issued", precision: 12, scale: 3, default: "0.0", null: false
    t.string "item_name", null: false
    t.decimal "new_stock_added", precision: 12, scale: 3, default: "0.0"
    t.text "notes"
    t.decimal "old_stock", precision: 12, scale: 3, default: "0.0"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.decimal "quantity", precision: 12, scale: 3, default: "0.0"
    t.integer "serial_no"
    t.string "supplier"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_grocery_items_on_category"
    t.index ["imported_at"], name: "index_grocery_items_on_imported_at"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "current_quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "daily_inventory_id", null: false
    t.string "item_name", null: false
    t.decimal "opening_quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["daily_inventory_id", "item_name"], name: "index_inventory_items_on_daily_inventory_id_and_item_name", unique: true
    t.index ["daily_inventory_id"], name: "index_inventory_items_on_daily_inventory_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_menu_items_on_category"
    t.index ["position"], name: "index_menu_items_on_position"
  end

  create_table "quantity_expenses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "inventory_item_id", null: false
    t.text "notes"
    t.decimal "quantity_used", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_item_id"], name: "index_quantity_expenses_on_inventory_item_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_team_members_on_position"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bill_line_items", "bills"
  add_foreign_key "bill_line_items", "menu_items"
  add_foreign_key "bills", "dining_tables"
  add_foreign_key "checklist_entries", "checklist_tasks"
  add_foreign_key "checklist_entries", "daily_checklists"
  add_foreign_key "inventory_items", "daily_inventories"
  add_foreign_key "quantity_expenses", "inventory_items"
end
