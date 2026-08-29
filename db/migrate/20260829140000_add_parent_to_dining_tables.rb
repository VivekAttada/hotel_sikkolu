class AddParentToDiningTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :dining_tables, :parent_dining_table, foreign_key: { to_table: :dining_tables }, null: true
  end
end
