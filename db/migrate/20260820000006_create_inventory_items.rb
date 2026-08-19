class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :daily_inventory, null: false, foreign_key: true
      t.string :item_name, null: false
      t.string :unit
      t.decimal :opening_quantity, precision: 10, scale: 2, default: 0, null: false
      t.decimal :current_quantity, precision: 10, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :inventory_items, [ :daily_inventory_id, :item_name ], unique: true
  end
end
