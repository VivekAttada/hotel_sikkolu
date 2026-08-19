class CreateQuantityExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :quantity_expenses do |t|
      t.references :inventory_item, null: false, foreign_key: true
      t.decimal :quantity_used, precision: 10, scale: 2, null: false
      t.text :notes

      t.timestamps
    end
  end
end
