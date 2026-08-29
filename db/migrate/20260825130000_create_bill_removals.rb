class CreateBillRemovals < ActiveRecord::Migration[8.1]
  def change
    create_table :bill_removals do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :menu_item, null: true, foreign_key: true
      t.string :item_name, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :quantity, null: false
      t.decimal :line_total, precision: 10, scale: 2, null: false, default: 0
      t.text :reason
      t.datetime :removed_at, null: false

      t.timestamps
    end

    add_index :bill_removals, :removed_at
  end
end
