class CreateBillManagementTables < ActiveRecord::Migration[8.1]
  def change
    create_table :dining_tables do |t|
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :dining_tables, :name, unique: true

    create_table :menu_items do |t|
      t.string :name, null: false
      t.string :category
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :menu_items, :category
    add_index :menu_items, :position

    create_table :bills do |t|
      t.references :dining_table, null: false, foreign_key: true
      t.string :bill_number, null: false
      t.string :status, null: false, default: "active"
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0
      t.datetime :opened_at, null: false
      t.datetime :paid_at

      t.timestamps
    end
    add_index :bills, :bill_number, unique: true
    add_index :bills, :status
    add_index :bills, :paid_at
    add_index :bills, [ :dining_table_id, :status ]

    create_table :bill_line_items do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :menu_item, foreign_key: true
      t.string :item_name, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.decimal :line_total, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end
  end
end
