class AddIssuedToGroceryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :grocery_items, :issued, :decimal, precision: 12, scale: 3, null: false, default: 0
  end
end
