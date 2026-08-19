class CreateGroceryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :grocery_items do |t|
      t.string :item_name, null: false
      t.string :category
      t.decimal :quantity, precision: 10, scale: 2, default: 0
      t.string :unit
      t.decimal :price, precision: 10, scale: 2, default: 0
      t.string :supplier
      t.text :notes
      t.datetime :imported_at, null: false

      t.timestamps
    end

    add_index :grocery_items, :category
    add_index :grocery_items, :imported_at
  end
end
