class HardenBillingAndAccess < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :name, :string
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_index :users, :unlock_token, unique: true

    add_column :bills, :dine_in_lock_key, :integer
    add_column :bills, :guest_name, :string
    add_column :bills, :guest_phone, :string
    add_column :bills, :discount_amount, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :bills, :discount_reason, :string
    add_column :bills, :complementary, :boolean, default: false, null: false
    add_column :bills, :cash_amount, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :bills, :upi_amount, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :bills, :card_amount, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :bills, :opened_by_id, :integer
    add_column :bills, :paid_by_id, :integer
    add_column :bills, :voided_by_id, :integer
    add_column :bills, :cancelled_by_id, :integer
    add_column :bills, :voided_at, :datetime
    add_column :bills, :void_reason, :text
    add_column :bills, :cancel_reason, :text

    add_index :bills, :opened_by_id
    add_index :bills, :paid_by_id
    add_index :bills, :voided_by_id
    add_index :bills, :voided_at

    create_table :grocery_imports do |t|
      t.datetime :imported_at, null: false
      t.integer :item_count, default: 0, null: false
      t.integer :imported_by_id
      t.timestamps
    end

    add_column :grocery_items, :grocery_import_id, :integer
    add_column :grocery_items, :superseded_at, :datetime
    add_index :grocery_items, :grocery_import_id
    add_index :grocery_items, :superseded_at

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE bills
          SET cash_amount = CASE WHEN payment_method = 'cash' THEN total ELSE 0 END,
              upi_amount = CASE WHEN payment_method = 'upi' THEN total ELSE 0 END,
              card_amount = CASE WHEN payment_method = 'card' THEN total ELSE 0 END
          WHERE status = 'paid' AND deleted_at IS NULL
        SQL

        takeaway_id = select_value("SELECT id FROM dining_tables WHERE name = 'Take Away' LIMIT 1")
        if takeaway_id
          execute <<~SQL.squish
            UPDATE bills
            SET dine_in_lock_key = dining_table_id
            WHERE status IN ('active', 'due')
              AND deleted_at IS NULL
              AND dining_table_id != #{takeaway_id.to_i}
          SQL
        end

        duplicates = select_all(<<~SQL.squish)
          SELECT dine_in_lock_key FROM bills
          WHERE dine_in_lock_key IS NOT NULL
          GROUP BY dine_in_lock_key
          HAVING COUNT(*) > 1
        SQL
        duplicates.each do |row|
          ids = select_values("SELECT id FROM bills WHERE dine_in_lock_key = #{row['dine_in_lock_key']} ORDER BY id DESC")
          ids.drop(1).each do |id|
            execute("UPDATE bills SET dine_in_lock_key = NULL WHERE id = #{id}")
          end
        end
      end
    end

    add_index :bills, :dine_in_lock_key, unique: true, where: "dine_in_lock_key IS NOT NULL"
  end

  def down
    remove_index :grocery_items, :superseded_at
    remove_index :grocery_items, :grocery_import_id
    remove_column :grocery_items, :superseded_at
    remove_column :grocery_items, :grocery_import_id
    drop_table :grocery_imports

    remove_index :bills, :dine_in_lock_key
    remove_index :bills, :voided_at
    remove_index :bills, :voided_by_id
    remove_index :bills, :paid_by_id
    remove_index :bills, :opened_by_id

    remove_column :bills, :cancel_reason
    remove_column :bills, :void_reason
    remove_column :bills, :voided_at
    remove_column :bills, :cancelled_by_id
    remove_column :bills, :voided_by_id
    remove_column :bills, :paid_by_id
    remove_column :bills, :opened_by_id
    remove_column :bills, :card_amount
    remove_column :bills, :upi_amount
    remove_column :bills, :cash_amount
    remove_column :bills, :complementary
    remove_column :bills, :discount_reason
    remove_column :bills, :discount_amount
    remove_column :bills, :guest_phone
    remove_column :bills, :guest_name
    remove_column :bills, :dine_in_lock_key

    remove_index :users, :unlock_token
    remove_column :users, :locked_at
    remove_column :users, :unlock_token
    remove_column :users, :failed_attempts
    remove_column :users, :name
  end
end
