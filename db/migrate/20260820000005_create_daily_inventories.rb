class CreateDailyInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_inventories do |t|
      t.date :inventory_date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :daily_inventories, :inventory_date, unique: true
  end
end
