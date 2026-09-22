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

ActiveRecord::Schema[8.1].define(version: 2026_09_22_060000) do
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

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "bill_edits", force: :cascade do |t|
    t.string "action", null: false
    t.integer "bill_id", null: false
    t.string "bill_number", null: false
    t.datetime "created_at", null: false
    t.json "details"
    t.date "service_date", null: false
    t.string "summary", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["action"], name: "index_bill_edits_on_action"
    t.index ["bill_id"], name: "index_bill_edits_on_bill_id"
    t.index ["created_at"], name: "index_bill_edits_on_created_at"
    t.index ["service_date"], name: "index_bill_edits_on_service_date"
    t.index ["user_id"], name: "index_bill_edits_on_user_id"
  end

  create_table "bill_line_items", force: :cascade do |t|
    t.integer "bill_id", null: false
    t.datetime "created_at", null: false
    t.string "item_name", null: false
    t.integer "kot_sent_quantity", default: 0, null: false
    t.decimal "line_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "menu_item_id"
    t.string "note"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_line_items_on_bill_id"
    t.index ["menu_item_id"], name: "index_bill_line_items_on_menu_item_id"
  end

  create_table "bill_removals", force: :cascade do |t|
    t.integer "bill_id", null: false
    t.datetime "created_at", null: false
    t.string "item_name", null: false
    t.decimal "line_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "menu_item_id"
    t.integer "quantity", null: false
    t.text "reason"
    t.datetime "removed_at", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_removals_on_bill_id"
    t.index ["menu_item_id"], name: "index_bill_removals_on_menu_item_id"
    t.index ["removed_at"], name: "index_bill_removals_on_removed_at"
  end

  create_table "bills", force: :cascade do |t|
    t.string "bill_number", null: false
    t.text "cancel_reason"
    t.integer "cancelled_by_id"
    t.decimal "card_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cash_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cgst_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "complementary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "dine_in_lock_key"
    t.integer "dining_table_id", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.string "discount_reason"
    t.string "guest_name"
    t.string "guest_phone"
    t.datetime "opened_at", null: false
    t.integer "opened_by_id"
    t.datetime "paid_at"
    t.integer "paid_by_id"
    t.string "payment_method"
    t.date "service_date", null: false
    t.decimal "sgst_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "active", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "upi_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.text "void_reason"
    t.datetime "voided_at"
    t.integer "voided_by_id"
    t.index ["deleted_at"], name: "index_bills_on_deleted_at"
    t.index ["dine_in_lock_key"], name: "index_bills_on_dine_in_lock_key", unique: true, where: "dine_in_lock_key IS NOT NULL"
    t.index ["dining_table_id", "status"], name: "index_bills_on_dining_table_id_and_status"
    t.index ["dining_table_id"], name: "index_bills_on_dining_table_id"
    t.index ["opened_by_id"], name: "index_bills_on_opened_by_id"
    t.index ["paid_at"], name: "index_bills_on_paid_at"
    t.index ["paid_by_id"], name: "index_bills_on_paid_by_id"
    t.index ["payment_method"], name: "index_bills_on_payment_method"
    t.index ["service_date", "bill_number"], name: "index_bills_on_service_date_and_bill_number", unique: true
    t.index ["status"], name: "index_bills_on_status"
    t.index ["voided_at"], name: "index_bills_on_voided_at"
    t.index ["voided_by_id"], name: "index_bills_on_voided_by_id"
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

  create_table "daily_sequences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.integer "last_number", default: 0, null: false
    t.date "service_date", null: false
    t.datetime "updated_at", null: false
    t.index ["service_date", "kind"], name: "index_daily_sequences_on_service_date_and_kind", unique: true
  end

  create_table "dining_tables", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "parent_dining_table_id"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dining_tables_on_name", unique: true
    t.index ["parent_dining_table_id"], name: "index_dining_tables_on_parent_dining_table_id"
  end

  create_table "grocery_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "imported_at", null: false
    t.integer "imported_by_id"
    t.integer "item_count", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "grocery_items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "grocery_import_id"
    t.datetime "imported_at", null: false
    t.decimal "issued", precision: 12, scale: 3, default: "0.0", null: false
    t.string "item_name", null: false
    t.decimal "new_stock_added", precision: 12, scale: 3, default: "0.0"
    t.text "notes"
    t.decimal "old_stock", precision: 12, scale: 3, default: "0.0"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.decimal "quantity", precision: 12, scale: 3, default: "0.0"
    t.integer "serial_no"
    t.datetime "superseded_at"
    t.string "supplier"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_grocery_items_on_category"
    t.index ["grocery_import_id"], name: "index_grocery_items_on_grocery_import_id"
    t.index ["imported_at"], name: "index_grocery_items_on_imported_at"
    t.index ["superseded_at"], name: "index_grocery_items_on_superseded_at"
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

  create_table "kitchen_tickets", force: :cascade do |t|
    t.integer "bill_id", null: false
    t.datetime "created_at", null: false
    t.integer "kot_number", null: false
    t.date "service_date", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_kitchen_tickets_on_bill_id"
    t.index ["service_date", "kot_number"], name: "index_kitchen_tickets_on_service_date_and_kot_number", unique: true
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
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "admin", null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bill_edits", "bills"
  add_foreign_key "bill_edits", "users"
  add_foreign_key "bill_line_items", "bills"
  add_foreign_key "bill_line_items", "menu_items"
  add_foreign_key "bill_removals", "bills"
  add_foreign_key "bill_removals", "menu_items"
  add_foreign_key "bills", "dining_tables"
  add_foreign_key "checklist_entries", "checklist_tasks"
  add_foreign_key "checklist_entries", "daily_checklists"
  add_foreign_key "dining_tables", "dining_tables", column: "parent_dining_table_id"
  add_foreign_key "inventory_items", "daily_inventories"
  add_foreign_key "kitchen_tickets", "bills"
  add_foreign_key "quantity_expenses", "inventory_items"
end
