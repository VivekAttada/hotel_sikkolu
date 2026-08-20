class UpdateGroceryItemsForClientSheet < ActiveRecord::Migration[8.1]
  def change
    add_column :grocery_items, :serial_no, :integer
    add_column :grocery_items, :old_stock, :decimal, precision: 12, scale: 3, default: 0
    add_column :grocery_items, :new_stock_added, :decimal, precision: 12, scale: 3, default: 0

    change_column :grocery_items, :quantity, :decimal, precision: 12, scale: 3, default: 0
  end
end
